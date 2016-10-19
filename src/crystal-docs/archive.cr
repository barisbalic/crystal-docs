module Crystal::Docs
  class Archive
    def self.extract(filename : String, path : String)
      system("tar -xvf #{filename} -C #{path} > /dev/null 2>&1")
    end
  end
end
