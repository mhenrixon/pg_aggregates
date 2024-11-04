# frozen_string_literal: true

module PgAggregates
  class AggregateDefinition
    attr_reader :name, :version

    def initialize(name, version:)
      @name = name
      @version = version
    end

    def to_sql
      File.read(path)
    end

    def path
      Rails.root.join("db", "aggregates", "#{name}_v#{version}.sql").to_s
    end

    def full_name
      name.to_s.include?(".") ? name.to_s : "public.#{name}"
    end
  end
end
