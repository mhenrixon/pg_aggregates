# frozen_string_literal: true

module PgAggregates
  module SchemaStatements
    # Reserved words to skip when checking function dependencies
    RESERVED_WORDS = ["public"].freeze

    def create_aggregate(name, version: nil, sql_definition: nil)
      raise ArgumentError, "Must provide either sql_definition or version" if sql_definition.nil? && version.nil?

      # First, check if the function already exists to avoid duplicate creation attempts
      return if aggregate_exists?(name)

      # Check if dependent functions exist before attempting to create
      check_dependent_functions(sql_definition || read_aggregate_definition(name, version))

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
    rescue ActiveRecord::StatementInvalid => e
      raise unless /function .* does not exist/.match?(e.message)

      puts "WARNING: Failed to create aggregate #{name} because a required function does not exist."
      puts "         This could indicate a dependency ordering issue."
      puts "         Error: #{e.message}"

      raise
    end

    def drop_aggregate(name, *arg_types, force: false)
      arg_types_sql = arg_types.any? ? "(#{arg_types.join(", ")})" : ""
      force_clause = force ? " CASCADE" : ""
      execute "DROP AGGREGATE IF EXISTS #{name}#{arg_types_sql}#{force_clause}"
    end

    private

    def aggregate_exists?(name)
      sql = <<-SQL
        SELECT 1
        FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE p.proname = '#{name}'
        AND p.prokind = 'a'
      SQL

      result = execute(sql)
      result.any?
    rescue StandardError
      false
    end

    def read_aggregate_definition(name, version)
      aggregate_definition = PgAggregates::AggregateDefinition.new(name, version: version)
      File.read(aggregate_definition.path) if File.exist?(aggregate_definition.path)
    end

    def check_dependent_functions(sql_definition)
      return unless sql_definition

      # Extract function names mentioned in the aggregate definition
      # Be careful to extract only the function name, not schema qualifiers
      function_matches = sql_definition.scan(/sfunc\s*=\s*['"]?(?:(?:[a-zA-Z0-9_]+\.)?([a-zA-Z0-9_]+))['"]?/i)
      function_names = function_matches.flatten.compact.uniq

      # For each referenced function, check if it exists
      function_names.each do |function_name|
        # Skip if function_name is empty or a reserved word
        next if function_name.nil? || function_name.empty? || RESERVED_WORDS.include?(function_name.downcase)

        check_sql = <<-SQL
          SELECT 1#{" "}
          FROM pg_catalog.pg_proc p
          JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
          WHERE p.proname = '#{function_name}'
          AND n.nspname = 'public'
        SQL

        result = execute(check_sql)
        unless result.any?
          puts "WARNING: Aggregate depends on function '#{function_name}' which does not exist"
          puts "         This will likely fail. Create the function first."
        end
      end
    rescue StandardError => e
      # Log the error but continue
      puts "WARNING: Error checking function dependencies: #{e.message}"
    end
  end
end
