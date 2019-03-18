module Undertaker
  class Storage

    class RedisBackend

      attr_accessor :flush_immediately

      def initialize
        @pending_deletions = Hash.new{|h,k| h[k] = Set.new }
      end

      def clear(key)
        Undertaker.config.redis.del(key)
      end

      def add(key, values)
        values = Array(values)
        return if values.empty?
        Undertaker.config.redis.sadd(key, values)
        Undertaker.config.redis.expire(key, Undertaker.config.cache_expiry)
      end

      def get(key)
        members = Undertaker.config.redis.smembers(key)
        members = Set.new(members) if members.is_a?(Array)
        if @pending_deletions.key?(key)
          members - @pending_deletions[key]
        else
          members
        end
      end

      def delete(key, value)
        @pending_deletions[key] << value.to_s
        flush if flush_immediately
      end

      def flush
        @pending_deletions.each do |key, values|
          Undertaker.config.redis.srem(key, values.to_a)
        end
        @pending_deletions.clear
      end
    end
  end
end
