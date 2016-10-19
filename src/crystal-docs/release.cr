module Crystal::Docs
  class Release

    def self.from_url(url : String, platform : String)
      match = url.match(/.*crystal-(.*)-#{platform}.*/)
      return Release.new(match[1], platform) if match

      raise Exception.new("Not a crystal release")
    end

    def self.from_path(path : String, platform : String)
      version = File.basename(path).gsub("crystal-", "")
      Release.new(version, platform)
    end

    def self.all(platform : String)
      response = HTTP::Client.get("https://github.com/crystal-lang/crystal/releases")

      links = response.body.scan(/download\/.*-#{platform}.tar.gz/i)
      links.map {|link| Release.from_url(link[0], platform) }
    end

    def initialize(version : String, platform : String)
      @version = version
      @platform = platform
    end

    def ==(other)
      version == other.version
    end

    def filename
      File.basename(url)
    end

    def binary
      File.join(RELEASE_PATH, "crystal-#{version}", "bin", "crystal")
    end

    def shards_binary
      File.join(RELEASE_PATH, "crystal-#{version}", "embedded", "bin", "shards")
    end

    def version
      @version
    end

    def platform
      @platform
    end

    def short_version
      @version.split("-").first
    end

    def url
      "https://github.com/crystal-lang/crystal/releases/download/#{short_version}/crystal-#{version}-#{platform}.tar.gz"
    end
  end
end
