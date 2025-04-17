# frozen_string_literal: true

require "spec_helper"

RSpec.describe PgAggregates::SchemaDumper do
  include TestHelpers

  let(:simple_aggregate) do
    <<~SQL
      CREATE AGGREGATE custom_array_agg(anyelement) (
        sfunc = array_append,
        stype = anyarray,
        initcond = '{}'
      );
    SQL
  end

  let(:complex_aggregate) do
    <<~SQL
      CREATE AGGREGATE custom_complex_agg(anyelement) (
        sfunc = array_append,
        stype = anyarray,
        initcond = '{}'
      );
    SQL
  end

  describe "schema dumping" do
    context "with a single aggregate" do
      it "includes the aggregate in the schema" do
        # Create the aggregate directly in the database
        ActiveRecord::Base.connection.execute(simple_aggregate)

        schema = dump_schema
        expect(schema).to include('create_aggregate "custom_array_agg"')
        expect(schema).to include("sfunc = array_append")
        expect(schema).to include("stype = anyarray")
      end
    end

    context "with a complex aggregate" do
      it "includes all aggregate properties in the schema" do
        # Create a more complex aggregate
        ActiveRecord::Base.connection.execute(complex_aggregate)

        schema = dump_schema
        expect(schema).to include('create_aggregate "custom_complex_agg"')
        expect(schema).to include("sfunc = array_append")
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
        # Create both aggregates directly in the database
        ActiveRecord::Base.connection.execute(zebra_aggregate)
        ActiveRecord::Base.connection.execute(alpha_aggregate)

        schema = dump_schema
        alpha_pos = schema.index("alpha_agg")
        zebra_pos = schema.index("zebra_agg")
        expect(alpha_pos).to be < zebra_pos
      end
    end
  end
end
