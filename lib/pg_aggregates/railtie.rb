# frozen_string_literal: true

module PgAggregates
  class Railtie < Rails::Railtie
    initializer "postgres_aggregates.load" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::ConnectionAdapters::AbstractAdapter.include PgAggregates::SchemaStatements
        ActiveRecord::Migration::CommandRecorder.include PgAggregates::CommandRecorder
        ActiveRecord::SchemaDumper.prepend PgAggregates::SchemaDumper
      end
    end
  end
end
