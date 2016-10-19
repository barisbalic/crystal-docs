require "ecr/macros"
require "html"
require "uri"
require "http"

# Bastardised copy of the original Crystal StaticFileHandler implementation.
module Crystal::Docs
  class ShardHandler < HTTP::Handler
    @public_dir : String

    def initialize(public_dir : String, fallthrough = true)
      @public_dir = File.expand_path public_dir
      @fallthrough = !!fallthrough
    end

    def call(context)
      unless context.request.method == "GET" || context.request.method == "HEAD"
        if @fallthrough
          call_next(context)
        else
          context.response.status_code = 405
          context.response.headers.add("Allow", "GET, HEAD")
        end
        return
      end

      original_path = context.request.path.not_nil!
      is_dir_path = original_path.ends_with? "/"
      request_path = URI.unescape(original_path)

      # File path cannot contains '\0' (NUL) because all filesystem I know
      # don't accept '\0' character as file name.
      if request_path.includes? '\0'
        context.response.status_code = 400
        return
      end

      expanded_path = File.expand_path(request_path, "/")
      if is_dir_path && !expanded_path.ends_with? "/"
        expanded_path = "#{expanded_path}/"
      end
      is_dir_path = expanded_path.ends_with? "/"

      file_path = File.join(@public_dir, expanded_path)
      is_dir = Dir.exists? file_path

      if request_path != expanded_path || is_dir && !is_dir_path
        redirect_to context, "#{expanded_path}#{is_dir && !is_dir_path ? "/" : ""}"
        return
      end

      is_root_path = file_path.gsub("/var/www/", "").empty?

      if Dir.exists?(file_path) && !is_root_path
        index_path = "#{file_path}index.html"
        if File.exists?(index_path)
          serve_file(index_path, context)
        else
          call_next(context)
        end
      elsif File.exists?(file_path)
        serve_file(file_path, context)
      elsif invalid_shard_path?(original_path)
        call_next(context)
        return
      else
        _, author, name = original_path.split("/")

        if (author != author.downcase) || (name != name.downcase)
          redirect_to context, "/#{author.downcase}/#{name.downcase}"
          return
        end

        shard = Shard.new(author, name)

        if shard.is_valid?
          serve_file("src/views/building_shard.ecr", context)
          return if shard.exists?

          spawn do
            shard.fetch
            shard.build_docs
          end

          return
        end

        call_next(context)
      end
    end

    private def invalid_shard_path?(path)
      path.count("/") < 2
    end

    private def serve_file(filename, context)
      content = MemoryIO.new( File.read(filename) )
      context.response.content_type = mime_type(filename)
      context.response.content_length = content.size
      IO.copy(content, context.response)
    end

    private def redirect_to(context, url)
      context.response.status_code = 302

      url = URI.escape(url) { |b| URI.unreserved?(b) || b != '/' }
      context.response.headers.add "Location", url
    end

    private def mime_type(path)
      case File.extname(path)
      when ".css"          then "text/css"
      when ".js"           then "application/javascript"
      else                      "text/html"
      end
    end
  end
end
