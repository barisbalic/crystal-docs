module Crystal::Docs
  class Shard
    @author : String
    @name : String
    @language : String

    def initialize(author : String, name : String)
      github_client = Crystal::Docs::GitHub::Client.new(GITHUB_TOKEN)
      repo = github_client.repository(author, name)

      @author = repo["owner"]["login"].as_s
      @name = repo["name"].as_s
      @language = repo["language"].as_s
    end

    def fetch
      return if exists?
      LOGGER.info "Fetching #{@author}/#{@name}"

      Dir.mkdir_p(repo_path)
      Crystal::Docs::Git.clone(@author, @name, repo_path)
    end

    def update
      LOGGER.info "Updating #{@author}/#{@name}"
      Crystal::Docs::Git.pull(@author, @name, repo_path)
    end

    def build_docs
      RELEASE_MANAGER.installed_releases.each do |release|
        LOGGER.info "Building #{@author}/#{@name} docs with #{release.version}"

        # Versions of shards pre 0.20.0 would generate an invalid lockfile for projects
        # without dependencies, so we ignore an initial failure.
        success = docker_run(release.version, repo_path, "sh ./first_pass.sh")

        lockfile = File.join(repo_path, "shard.lock")

        unless success
          purge_lockfile!
          success = docker_run(release.version, repo_path, "sh ./second_pass.sh")
        end

        if success
          # stdlib `FileUtils.cp_r` tries to recreate existing directories causing an error.
          Dir.mkdir_p(doc_path) unless Dir.exists?(doc_path)
          source_path = File.join(repo_path, "doc", "*")
          system("cp -R #{source_path} #{doc_path}")
          return
        end

        purge_lockfile!
      end

      LOGGER.info "Failed to build #{@author}/#{@name}"

      Dir.mkdir_p(doc_path) unless Dir.exists?(doc_path)
      content = File.read("src/views/failed.ecr")
      File.write(File.join(doc_path, "index.html"), content)
      File.write(File.join(doc_path, "error.lock"), "")
    end

    def repo_path
      File.join(REPO_PATH, @author, @name)
    end

    def doc_path
      File.join(DOC_PATH, @author, @name)
    end

    def is_broken?
      File.exists?(File.join(doc_path, "error.lock"))
    end

    def purge_lockfile!
      lockfile = File.join(repo_path, "shard.lock")
      File.delete(lockfile) if File.exists?(lockfile)
    end

    def is_valid?
      @language == "Crystal"
    end

    def exists?
      Dir.exists?(repo_path)
    end

    private def docker_run(crystal_version, repo_path, command)
      crystal_path = File.join(RELEASE_PATH, "crystal-#{crystal_version}")
      system("docker run -v #{crystal_path}:/crystal -v #{repo_path}:/repo -t crystal-sandbox #{command}")
    end
  end
end
