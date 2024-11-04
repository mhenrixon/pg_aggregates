# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :db do
  desc "Set up test database"
  task :setup do
    require "active_record"
    require "fileutils"
    require "logger"

    # Set up test database
    ActiveRecord::Base.establish_connection(
      adapter: "postgresql",
      database: "postgres",
      username: ENV.fetch("POSTGRES_USER", "postgres"),
      password: ENV.fetch("POSTGRES_PASSWORD", "postgres"),
      host: ENV.fetch("POSTGRES_HOST", "localhost")
    )

    begin
      ActiveRecord::Base.connection.drop_database("pg_aggregates_test")
    rescue StandardError
      nil
    end
    ActiveRecord::Base.connection.create_database("pg_aggregates_test")
  end
end

desc "Runs spec after setting up database"
task spec: "db:setup"

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]
