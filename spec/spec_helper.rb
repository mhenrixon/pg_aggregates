# frozen_string_literal: true

# spec/spec_helper.rb
require "bundler/setup"
require "logger"
require "active_record"
require "pg_aggregates"
require "database_cleaner"
require "pathname"

# Set up a fake Rails.root
module Rails
  def self.root
    @root ||= Pathname.new(File.expand_path("dummy", __dir__))
  end
end

# Set up logging
ActiveRecord::Base.logger = Logger.new($stdout) if ENV["DEBUG"]

# Helper methods for version compatibility
module VersionHelper
  def rails_8_or_newer?
    ActiveRecord.version >= Gem::Version.new("8.0.0")
  end

  def rails_7_or_newer?
    ActiveRecord.version >= Gem::Version.new("7.0.0")
  end

  def rails_6_1_or_newer?
    ActiveRecord.version >= Gem::Version.new("6.1.0")
  end

  def dump_schema
    stream = StringIO.new

    # The most reliable approach is to check for method availability rather than version
    if rails_8_or_newer?
      # Rails 8.0+ uses connection_pool and with_connection
      ActiveRecord::SchemaDumper.dump(
        ActiveRecord::Base.connection_pool,
        stream
      )
    elsif ActiveRecord::Base.connection_pool.respond_to?(:create_schema_dumper) # rubocop:disable Lint/DuplicateBranch
      # Some versions use connection_pool directly and it has create_schema_dumper
      ActiveRecord::SchemaDumper.dump(
        ActiveRecord::Base.connection_pool,
        stream
      )
    elsif ActiveRecord::Base.connection.respond_to?(:schema_dumper)
      # Some versions use schema_dumper instead
      dumper = ActiveRecord::Base.connection.schema_dumper
      dumper.dump(stream)
    else
      # Fallback for any other version
      ActiveRecord::SchemaDumper.dump(
        ActiveRecord::Base.connection,
        stream
      )
    end

    stream.string
  end

  def verify_file_exists(path)
    expect(File.exist?(path)).to be true
  end

  def migration_file(filename)
    Dir[File.join(destination_root, "db/migrate/*#{filename}")].first
  end
end

# Helper methods for tests
module TestHelpers
  def with_aggregate_file(name, version, content)
    dir = Rails.root.join("db/aggregates")
    FileUtils.mkdir_p(dir)
    file_path = dir.join("#{name}_v#{version}.sql")
    File.write(file_path, content)
    yield
  ensure
    FileUtils.rm_f(file_path)
  end
end

# Database setup helper
def setup_database
  config = {
    adapter: "postgresql",
    database: ENV.fetch("POSTGRES_DB", "pg_test"),
    username: ENV.fetch("POSTGRES_USER", "postgres"),
    password: ENV.fetch("POSTGRES_PASSWORD", "postgres"),
    host: ENV.fetch("POSTGRES_HOST", "localhost")
  }

  # First, connect to postgres database to create/drop test database
  ActiveRecord::Base.establish_connection(config.merge(database: "postgres"))
  begin
    ActiveRecord::Base.connection.drop_database(config[:database])
  rescue StandardError
    nil
  end
  ActiveRecord::Base.connection.create_database(config[:database])
  ActiveRecord::Base.establish_connection(config)

  # Enable required PostgreSQL extensions
  ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS plpgsql")
  ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS intarray")
end

# Set up test database
setup_database

# Ensure our modules are included
ActiveRecord::ConnectionAdapters::AbstractAdapter.include PgAggregates::SchemaStatements

# This needs to happen after connection is established
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.include PgAggregates::SchemaStatements
end

# Include our schema dumper
ActiveRecord::SchemaDumper.prepend PgAggregates::SchemaDumper

RSpec.configure do |config|
  config.include VersionHelper
  config.include TestHelpers

  config.before(:suite) do
    # Create the dummy app directory structure
    FileUtils.mkdir_p(Rails.root.join("db/aggregates"))

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
    # Clean up the dummy app
    FileUtils.rm_rf(Rails.root)
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Add helper functions needed for tests
  config.before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION array_append(anyarray, anyelement)
      RETURNS anyarray AS $$
      BEGIN
        RETURN array_cat($1, ARRAY[$2]);
      END;
      $$ LANGUAGE plpgsql IMMUTABLE;
    SQL

    # Add int4pl function for aggregate tests
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION int4pl(integer, integer)
      RETURNS integer AS $$
      BEGIN
        RETURN $1 + $2;
      END;
      $$ LANGUAGE plpgsql IMMUTABLE;
    SQL
  end
end
