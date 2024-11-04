# frozen_string_literal: true

module PgAggregates
  module SchemaStatements
    def create_aggregate(name, version: nil, sql_definition: nil)
      raise ArgumentError, "Must provide either sql_definition or version" if sql_definition.nil? && version.nil?

      if sql_definition
        execute sql_definition
      else
        # Fallback to file-based definition if needed
        aggregate_definition = PgAggregates::AggregateDefinition.new(name, version: version)

        # Check if file exists before trying to read it
        unless File.exist?(aggregate_definition.path)
          raise ArgumentError, "Could not find aggregate definition file: #{aggregate_definition.path}"
        end

        execute aggregate_definition.to_sql
      end
    end

    def drop_aggregate(name, *arg_types, force: false)
      arg_types_sql = arg_types.any? ? "(#{arg_types.join(", ")})" : ""
      force_clause = force ? " CASCADE" : ""
      execute "DROP AGGREGATE IF EXISTS #{name}#{arg_types_sql}#{force_clause}"
    end
  end
end
