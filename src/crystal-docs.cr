require "ecr/macros"
require "http/client"
require "file_utils"
require "logger"
require "kemal"
require "./crystal-docs/github/client"
require "./crystal-docs/*"


module Crystal::Docs
  GA_TRACKING_ID = ENV["GA_TRACKING_ID"] || ""
  GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
  RELEASE_PATH = ENV["RELEASE_PATH"]
  REPO_PATH = ENV["REPO_PATH"]
  DOC_PATH = ENV["DOC_PATH"]
  PLATFORM = ENV["CRYSTALDOCS_PLATFORM"]

  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::INFO

  RELEASE_MANAGER = ReleaseManager.new(RELEASE_PATH, PLATFORM)
  RELEASE_MANAGER.start

  SHARD_WATCHER = ShardWatcher.new(REPO_PATH)
  SHARD_WATCHER.start

  error 404 do
    render "src/views/404.ecr", "src/views/layouts/layout.ecr"
  end

  get "/badge.svg" do |env|
    style = env.params.query.fetch("style", "")
    response = HTTP::Client.get("https://img.shields.io/badge/crystal--docs-ref-2E1052.svg?style=#{style}")
    env.response.content_type = "image/svg+xml"
    response.body
  end

  get "/" do
    render "src/views/home.ecr", "src/views/layouts/layout.ecr"
  end

  get "/about" do
    releases = RELEASE_MANAGER.installed_releases
    render "src/views/about.ecr", "src/views/layouts/layout.ecr"
  end
end

Kemal.config.add_handler(Crystal::Docs::ShardHandler.new(Crystal::Docs::DOC_PATH))
Kemal.run
