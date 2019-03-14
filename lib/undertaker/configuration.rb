module Undertaker
  class Configuration

    attr_accessor :redis, :tracked_classes, :error_handler

    STORAGE_BACKENDS = {
      memory: Storage::MemoryBackend,
      redis: Storage::RedisBackend,
    }

    def backend=(backend_type)
      @backend ||= STORAGE_BACKENDS.fetch(backend_type).new
    end

    def backend
      if @backend
        @backend
      else
        raise "#{self.class.name}#backend is not configured"
      end
    end

  end
end
