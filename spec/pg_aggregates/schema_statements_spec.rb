# frozen_string_literal: true

# spec/pg_aggregates/schema_statements_spec.rb
require "spec_helper"

RSpec.describe PgAggregates::SchemaStatements do
  include TestHelpers

  let(:connection) { ActiveRecord::Base.connection }

  describe "#create_aggregate" do
    let(:aggregate_sql) do
      <<~SQL
        CREATE AGGREGATE sum2(int4)
        (
          sfunc = int4pl,
          stype = int4,
          initcond = '0'
        );
      SQL
    end

    it "creates an aggregate from sql_definition" do
      connection.create_aggregate("sum2", sql_definition: aggregate_sql)

      result = connection.select_value(<<-SQL)
        SELECT EXISTS (
          SELECT 1#{" "}
          FROM pg_proc p#{" "}
          JOIN pg_namespace n ON p.pronamespace = n.oid#{" "}
          WHERE p.prokind = 'a'#{" "}
          AND p.proname = 'sum2'
          AND n.nspname = 'public'
        )
      SQL

      expect(result).to be true
    end

    it "creates an aggregate from a versioned file" do
      with_aggregate_file("sum2", 1, aggregate_sql) do
        connection.create_aggregate("sum2", version: 1)

        result = connection.select_value(<<-SQL)
          SELECT EXISTS (
            SELECT 1#{" "}
            FROM pg_proc p#{" "}
            JOIN pg_namespace n ON p.pronamespace = n.oid#{" "}
            WHERE p.prokind = 'a'#{" "}
            AND p.proname = 'sum2'
            AND n.nspname = 'public'
          )
        SQL

        expect(result).to be true
      end
    end

    it "raises an error when neither sql_definition nor version is provided" do
      expect do
        connection.create_aggregate("bad_agg")
      end.to raise_error(ArgumentError)
    end
  end

  describe "#drop_aggregate" do
    before do
      connection.execute(<<~SQL)
        CREATE AGGREGATE sum2(int4)
        (
          sfunc = int4pl,
          stype = int4,
          initcond = '0'
        );
      SQL
    end

    it "drops an existing aggregate" do
      connection.drop_aggregate("sum2", "int4")

      result = connection.select_value(<<-SQL)
        SELECT EXISTS (
          SELECT 1#{" "}
          FROM pg_proc p#{" "}
          JOIN pg_namespace n ON p.pronamespace = n.oid#{" "}
          WHERE p.prokind = 'a'#{" "}
          AND p.proname = 'sum2'
          AND n.nspname = 'public'
        )
      SQL

      expect(result).to be false
    end

    it "doesn't raise error when dropping non-existent aggregate" do
      expect do
        connection.drop_aggregate("nonexistent_agg", "int4")
      end.not_to raise_error
    end

    it "drops aggregate with CASCADE when force: true" do
      # Create a dependent view
      connection.execute(<<~SQL)
        CREATE VIEW test_view AS#{" "}
        SELECT sum2(id::int4) FROM (VALUES (1)) AS t(id);
      SQL

      expect do
        connection.drop_aggregate("sum2", "int4", force: true)
      end.not_to raise_error

      # Check if view exists using a more compatible approach
      view_exists = connection.select_value(<<~SQL)
        SELECT EXISTS (
          SELECT 1 FROM pg_catalog.pg_class c
          JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
          WHERE c.relname = 'test_view'
          AND n.nspname = 'public'
          AND c.relkind = 'v'
        )
      SQL
      expect(view_exists).to be false
    end
  end
end
