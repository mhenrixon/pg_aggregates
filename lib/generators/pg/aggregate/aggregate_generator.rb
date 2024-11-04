# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Pg
  module Generators
    class AggregateGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      class_option :version,
                   type: :string,
                   default: "1",
                   desc: "Specify a version for the aggregate"

      def create_aggregate_file
        @version = options[:version]
        @aggregate_name = file_name

        template(
          "aggregate.sql.erb",
          "db/aggregates/#{file_name}_v#{@version}.sql"
        )
      end

      def create_migration_file
        @version = options[:version]
        @aggregate_name = file_name
        @migration_version = migration_version

        migration_template(
          "migration.rb.erb",
          "db/migrate/create_aggregate_#{file_name}.rb"
        )
      end

      private

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end
