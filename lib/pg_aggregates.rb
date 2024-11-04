# frozen_string_literal: true

require "active_record/railtie"

require_relative "pg_aggregates/file_version"
require_relative "pg_aggregates/aggregate_definition"
require_relative "pg_aggregates/schema_statements"
require_relative "pg_aggregates/command_recorder"
require_relative "pg_aggregates/schema_dumper"
require_relative "pg_aggregates/railtie"

module PgAggregates
  class Error < StandardError; end

  class << self
    def database
      ActiveRecord::Base.connection
    end
  end
end
