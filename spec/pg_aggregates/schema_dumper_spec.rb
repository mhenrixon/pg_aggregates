# frozen_string_literal: true

require "spec_helper"

RSpec.describe PgAggregates::SchemaDumper do
  include TestHelpers

  let(:simple_aggregate) do
    <<~SQL
      CREATE AGGREGATE array_agg(anyelement) (
        sfunc = array_append,
        stype = anyarray,
        initcond = '{}'
      );
    SQL
  end

  let(:complex_aggregate) do
    <<~SQL
      CREATE AGGREGATE array_agg(anynonarray) (
        sfunc = array_append,
        stype = anyarray,
        sspace = 1000,
        finalfunc = array_larger,
        initcond = '{}'
      );
    SQL
  end

  describe "schema dumping" do
    context "with a single version" do
      it "includes the aggregate in the schema" do
        with_aggregate_file("array_agg", 1, simple_aggregate) do
          schema = dump_schema
          expect(schema).to include('create_aggregate "array_agg"')
          expect(schema).to include("sfunc = array_append")
          expect(schema).to include("stype = anyarray")
          expect(schema).not_to include("versions:")
        end
      end
    end

    context "with multiple versions" do
      it "uses the latest version in the schema" do
        with_aggregate_file("array_agg", 1, simple_aggregate) do
          with_aggregate_file("array_agg", 2, complex_aggregate) do
            schema = dump_schema
            expect(schema).to include('create_aggregate "array_agg"')
            expect(schema).to include("sspace = 1000")
            expect(schema).to include("finalfunc = array_larger")
            expect(schema).to include("versions: 1, 2")
          end
        end
      end
    end

    context "with multiple aggregates" do
      let(:zebra_aggregate) do
        <<~SQL
          CREATE AGGREGATE zebra_agg(anyelement) (
            sfunc = array_append,
            stype = anyarray,
            initcond = '{}'
          );
        SQL
      end

      let(:alpha_aggregate) do
        <<~SQL
          CREATE AGGREGATE alpha_agg(anyelement) (
            sfunc = array_append,
            stype = anyarray,
            initcond = '{}'
          );
        SQL
      end

      it "sorts aggregates alphabetically" do
        with_aggregate_file("zebra_agg", 1, zebra_aggregate) do
          with_aggregate_file("alpha_agg", 1, alpha_aggregate) do
            schema = dump_schema
            alpha_pos = schema.index("alpha_agg")
            zebra_pos = schema.index("zebra_agg")
            expect(alpha_pos).to be < zebra_pos
          end
        end
      end
    end
  end
end
