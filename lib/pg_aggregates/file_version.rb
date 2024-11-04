# frozen_string_literal: true

module PgAggregates
  class FileVersion
    attr_reader :path, :name, :version

    def initialize(path)
      @path = Pathname.new(path)
      @name = @path.basename.to_s.sub(/_v\d+\.sql$/, "")
      @version = extract_version
    end

    def sql_definition
      File.read(path).strip
    end

    private

    def extract_version
      if (match = @path.basename.to_s.match(/_v(\d+)\.sql$/))
        match[1].to_i
      else
        0
      end
    end
  end
end
