$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "sqlite_shards"
require "sqlite3"
require "active_support/test_case"
require "minitest/autorun"

ActiveSupport.test_order = :random
