# frozen_string_literal: true

require "active_record/railtie"

require_relative "pg_aggregates/file_version"
require_relative "pg_aggregates/aggregate_definition"
require_relative "pg_aggregates/schema_statements"
require_relative "pg_aggregates/command_recorder"
require_relative "pg_aggregates/schema_dumper"
require_relative "pg_aggregates/railtie"

module PgAggregates
  module_function

  class Error < StandardError; end

  def load
    # This is crucial - we must ensure proper load order:
    # 1. extensions
    # 2. types
    # 3. functions
    # 4. aggregates
    # 5. tables

    # Add schema statements and command recorder
    ActiveRecord::ConnectionAdapters::AbstractAdapter.include PgAggregates::SchemaStatements
    ActiveRecord::Migration::CommandRecorder.include PgAggregates::CommandRecorder

    # Hook into the schema dumper, with dependency awareness
    ActiveRecord::SchemaDumper.prepend PgAggregates::SchemaDumper
  end

  def database
    ActiveRecord::Base.connection
  end
end
