module Undertaker
  class Storage

    class MemoryBackend

      attr_accessor :flush_immediately
      attr_reader :pending_deletions

      def initialize
        @mapping = Hash.new{|h,k| h[k] = Set.new }
        @pending_deletions = Hash.new{|h,k| h[k] = Set.new }
      end

      def clear(key)
        @mapping.clear
      end

      def add(key, values)
        @mapping[key].merge(Array(values))
      end

      def get(key)
        if @pending_deletions.key?(key)
          @mapping[key] - @pending_deletions[key]
        else
          @mapping[key]
        end
      end

      def delete(key, value)
        @pending_deletions[key] << value.to_s
        flush if flush_immediately
      end

      def flush
        @pending_deletions.each do |key, values|
          @mapping[key].subtract(values)
        end
        @pending_deletions.clear
      end
    end
  end
end
