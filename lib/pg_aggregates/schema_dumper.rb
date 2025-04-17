# frozen_string_literal: true

require "ostruct"

module PgAggregates
  module SchemaDumper
    # Define a Struct for aggregate information
    AggregateDefinition = Struct.new(:name, :definition)

    # Override the tables method to inject aggregate dumping *after* functions (handled by fx)
    # but *before* tables.
    def tables(stream)
      # Dump custom aggregates first
      dump_custom_aggregates(stream)

      stream.puts # Add a newline for separation before tables

      # Call the next implementation (likely fx's tables or Rails' tables)
      super
    end

    private

    def dump_custom_aggregates(stream)
      aggregates = dumpable_aggregates_in_database

      return if aggregates.empty?

      stream.puts "  # These are custom PostgreSQL aggregates that were defined"

      # Sort by name to ensure consistent ordering
      aggregates.sort_by(&:name).each do |aggregate|
        stream.puts <<~AGG
            create_aggregate "#{aggregate.name}", sql_definition: <<-SQL
          #{aggregate.definition}
            SQL

        AGG
      end
    end

    # Fetches all aggregate functions from the database
    def dumpable_aggregates_in_database
      @dumpable_aggregates_in_database ||= begin
        # SQL query to fetch aggregate functions from PostgreSQL
        # This query gets the aggregate name and constructs the CREATE AGGREGATE statement
        sql = <<~SQL
          SELECT
            p.proname AS name,
            format(
              'CREATE AGGREGATE %s(%s) (%s);',
              p.proname,
              pg_get_function_arguments(p.oid),
              array_to_string(array_agg(format('%s = %s', option_name, option_value)), E',\n    ')
            ) AS definition
          FROM pg_proc p
          JOIN pg_namespace n ON p.pronamespace = n.oid
          JOIN pg_aggregate a ON a.aggfnoid = p.oid
          JOIN LATERAL (
            SELECT 'sfunc' AS option_name, p2.proname::text AS option_value
            FROM pg_proc p2
            WHERE p2.oid = a.aggtransfn
            UNION ALL
            SELECT 'stype', format_type(a.aggtranstype, NULL)
            UNION ALL
            SELECT 'finalfunc', p3.proname::text
            FROM pg_proc p3
            WHERE p3.oid = a.aggfinalfn AND a.aggfinalfn != 0
            UNION ALL
            SELECT 'initcond', quote_literal(a.agginitval)
            WHERE a.agginitval IS NOT NULL
          ) options ON true
          WHERE n.nspname = 'public'
          GROUP BY p.proname, p.oid
          ORDER BY p.proname;
        SQL

        # Get the appropriate connection
        connection = ActiveRecord::Base.connection

        # Execute the query and transform results into aggregate objects
        connection.execute(sql).map do |result|
          AggregateDefinition.new(
            result["name"],
            result["definition"].strip
          )
        end
      end
    end
  end
end
