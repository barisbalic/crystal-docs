module Crystal::Docs
  class ShardWatcher
    def initialize(directory : String)
      @directory = directory
    end

    def start
      spawn do
        loop do
          sleep 30.minutes
          update_shards
        end
      end
    end

    private def update_shards
      LOGGER.info "Updating shards..."
      Dir.foreach(@directory) do |author|
        path = File.join(@directory, author)
        next unless Dir.exists?(path)
        next unless is_dir?(author)

        Dir.foreach(path) do |name|
          next unless is_dir?(name)

          shard = Shard.new(author, name)
          if shard.is_broken?
            LOGGER.info "Skipping #{author}/#{name} as it was previously broken"
            next
          end

          shard.update
          shard.build_docs
        end
      end
      LOGGER.info "Finished updating shards."
    end

    private def is_dir?(name : String)
      return false if ["..", "."].includes?(name)
      true
    end
  end
end
