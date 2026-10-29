require_relative "lib/sqlite_shards/version"

Gem::Specification.new do |spec|
  spec.name = "sqlite_shards"
  spec.version = SqliteShards::VERSION
  spec.authors = ["Alessandro Rodi"]
  spec.email = ["alessandro.rodi@renuo.ch"]
  spec.homepage = "https://github.com/renuo/sqlite_shards"
  spec.summary = "Active Record models whose data lives in SQLite files picked at runtime, one database per file."
  spec.description = "Include SqliteShards in an abstract Active Record class and its models read and write the " \
    "SQLite file you pass to with_database, each file a shard of its own, migrated on first use."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "LICENSE.txt", "README.md", "CHANGELOG.md"]

  spec.add_dependency "activerecord", "~> 8.0"
  spec.add_dependency "sqlite3", "~> 2.0"
end
