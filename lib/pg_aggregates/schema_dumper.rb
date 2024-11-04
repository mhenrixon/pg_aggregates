# frozen_string_literal: true

module PgAggregates
  module SchemaDumper
    def tables(stream)
      # First dump aggregates
      dump_custom_aggregates(stream)
      stream.puts

      super
    end

    private

    def dump_custom_aggregates(stream)
      # Group all versions of each aggregate
      aggregate_versions = {}

      Dir.glob(Rails.root.join("db/aggregates/*_v*.sql").to_s).each do |file|
        file_version = FileVersion.new(file)
        aggregate_versions[file_version.name] ||= []
        aggregate_versions[file_version.name] << file_version
      end

      return if aggregate_versions.empty?

      stream.puts "  # These are custom PostgreSQL aggregates that were defined"

      # For each aggregate, use the latest version
      latest_versions = aggregate_versions.transform_values do |versions|
        versions.max_by(&:version)
      end

      # Sort by name to ensure consistent ordering
      latest_versions.keys.sort.each do |aggregate_name|
        file_version = latest_versions[aggregate_name]

        # Add a comment showing the version history
        all_versions = aggregate_versions[aggregate_name].map(&:version).sort
        version_comment = all_versions.size > 1 ? " -- versions: #{all_versions.join(", ")}" : ""

        stream.puts <<-AGG
  create_aggregate "#{aggregate_name}", sql_definition: <<-SQL#{version_comment}
    #{file_version.sql_definition}
  SQL

        AGG
      end
    end
  end
end
