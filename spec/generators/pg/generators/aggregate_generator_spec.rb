# frozen_string_literal: true

require "spec_helper"
require "ammeter/init"
require "generators/pg/aggregate/aggregate_generator"

RSpec.describe Pg::Generators::AggregateGenerator, type: :generator do
  include TestHelpers

  destination File.expand_path("../../tmp", __dir__)

  before do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, "db", "aggregates"))
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  describe "generator" do
    context "with default version" do
      before { run_generator %w[sum_squares] }

      it "creates aggregate file" do
        aggregate_file = "db/aggregates/sum_squares_v1.sql"
        verify_file_exists(File.join(destination_root, aggregate_file))
        expect(File.read(File.join(destination_root, aggregate_file))).to include("CREATE AGGREGATE sum_squares")
      end

      it "creates migration file" do
        migration_path = File.join(destination_root, "db/migrate")
        migration_file = Dir["#{migration_path}/*create_aggregate_sum_squares.rb"].first
        verify_file_exists(migration_file)
        expect(File.read(migration_file)).to match(/create_aggregate "sum_squares", version: 1/)
      end
    end

    context "with specified version" do
      before { run_generator %w[array_sum --version 2] }

      it "creates versioned aggregate file" do
        aggregate_file = "db/aggregates/array_sum_v2.sql"
        verify_file_exists(File.join(destination_root, aggregate_file))
        expect(File.read(File.join(destination_root, aggregate_file))).to include("CREATE AGGREGATE array_sum")
      end

      it "creates migration with specified version" do
        migration_path = File.join(destination_root, "db/migrate")
        migration_file = Dir["#{migration_path}/*create_aggregate_array_sum.rb"].first
        verify_file_exists(migration_file)
        expect(File.read(migration_file)).to match(/create_aggregate "array_sum", version: 2/)
      end
    end
  end
end
