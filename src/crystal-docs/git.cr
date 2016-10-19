module Crystal::Docs
  class Git
    def self.clone(author : String, shard : String, path : String)
      url = "https://github.com/#{author}/#{shard}.git"
      system("git clone #{url} #{path} > /dev/null 2>&1")
    end

    def self.pull(author : String, shard : String, path : String)
      system("cd #{path} && git pull > /dev/null 2>&1")
    end
  end
end
