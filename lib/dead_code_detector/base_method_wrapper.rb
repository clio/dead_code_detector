module DeadCodeDetector
  class BaseMethodWrapper

    attr_reader :klass

    def initialize(klass)
      @klass = klass
    end

    class << self
      def delimiter
        raise NotImeplementedError
      end

      def track_method(klass, method_name)
        MethodCacher.track_method(klass.name, method_name, delimiter: delimiter)
      end

      def unwrap_method(klass, original_method)
        raise NotImplementedError
      end
    end

    def wrap_methods!
      potentially_unused_methods.each do |method_name|
        wrap_method(get_method(method_name))
      end
    end

    def number_of_tracked_methods
      default_methods.count
    end

    def populate_cache
      return if number_of_tracked_methods.zero?
      MethodCacher.populate_method_cache(
        klass.name,
        default_methods,
        delimiter: self.class.delimiter
      )
    end

    private

    def default_methods
      raise NotImplementedError
    end

    def get_method(method_name)
      raise NotImplementedError
    end

    def wrap_method(original_method)
      raise NotImplementedError
    end

    def owned_method?(method_name)
      raise NotImplementedError
    end

    # Due to caching, new methods won't show up automatically in this call
    def potentially_unused_methods
      stored_methods = MethodCacher.potentially_unused_methods(
        klass.name,
        delimiter: self.class.delimiter
      )
      stored_methods & default_methods.map(&:to_s)
    end

  end
end
