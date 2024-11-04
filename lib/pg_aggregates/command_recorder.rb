# frozen_string_literal: true

module PgAggregates
  module CommandRecorder
    def create_aggregate(*args, &block)
      record(:create_aggregate, args, &block)
    end

    def drop_aggregate(*args)
      record(:drop_aggregate, args)
    end

    def invert_create_aggregate(args)
      [:drop_aggregate, args]
    end

    def invert_drop_aggregate(args)
      [:create_aggregate, args]
    end
  end
end
