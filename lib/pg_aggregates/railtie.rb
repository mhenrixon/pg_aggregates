# frozen_string_literal: true

module PgAggregates
  class Railtie < Rails::Railtie
    initializer "pg_aggregates.load", before: "fx.load" do
      ActiveSupport.on_load(:active_record) do
        PgAggregates.load
      end
    end
  end
end
