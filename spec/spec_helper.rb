require "bundler/setup"
require "active_record"
require "pry"

ActiveRecord::Base.establish_connection adapter: "mysql2", database: "cursor_pagination_test", username: "root"

load File.dirname(__FILE__) + '/schema.rb'
require File.dirname(__FILE__) + '/models.rb'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
