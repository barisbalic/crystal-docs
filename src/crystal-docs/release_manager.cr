module Crystal::Docs
  class ReleaseManager
    @channel = Channel(Release).new
    @installed_releases = Array(Release).new

    def initialize(download_path : String, platform : String)
      @platform = platform
      Dir.mkdir(download_path) unless Dir.exists?(download_path)

      spawn do
        loop do
          release = @channel.receive

          spawn do
            LOGGER.info "Downloading release #{release.version}"
            system("wget --directory-prefix=#{download_path} #{release.url} > /dev/null 2>&1")

            Archive.extract(File.join(download_path, release.filename), download_path)

            LOGGER.info "Release #{release.version} is now available"
            @installed_releases << release
          end
        end
      end

      Dir.foreach(download_path) do |release_dir|
        release_path = File.join(download_path, release_dir)
        next if ["..", "."].includes?(release_dir)
        next unless Dir.exists?(release_path)

        release = Release.from_path(release_path, @platform)
        LOGGER.info "Added #{release.version} (local copy)"
        @installed_releases << release
      end
    end

    def start
      spawn do
        loop do
          fetch_new_releases(@platform)
          sleep 1.hour
        end
      end
    end

    def installed_releases
      @installed_releases.sort_by {|release| release.version }.reverse
    end

    def new_releases(releases)
      new_versions = releases.map(&.version)
      installed_versions = @installed_releases.map(&.version)
      missing_versions = new_versions - installed_versions

      releases.select {|release| missing_versions.includes?(release.version)}
    end

    private def fetch_new_releases(platform : String)
      LOGGER.info "Checking for new releases..."
      releases = Release.all(platform)

      new_releases(releases).each do |release|
        @channel.send(release)
      end
    end
  end
end
