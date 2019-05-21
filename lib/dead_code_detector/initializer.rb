module DeadCodeDetector
  class Initializer

    class << self

      def refresh_caches
        DeadCodeDetector.config.classes_to_monitor.each do |klass|
          refresh_cache_for(klass)
        end
      end

      def refresh_cache_for(klass)
        @enabled = false
        classes = [klass, *descendants_of(klass)]
        classes.each do |class_to_enable|
          cache_methods_for(class_to_enable)
        end
      end

      def clear_cache
        MethodCacher.clear_cache
      end

      def enable(klass)
        ClassMethodWrapper.new(klass).wrap_methods!
        InstanceMethodWrapper.new(klass).wrap_methods!
      end

      def enable_for_cached_classes!
        return if @enabled
        return unless allowed?
        @enabled = true
        MethodCacher.cached_classes.each do |class_name|
          klass = Object.const_get(class_name) rescue nil
          enable(klass) if klass
        end
      end

      def allowed?
        if DeadCodeDetector.config.allowed.respond_to?(:call)
          DeadCodeDetector.config.allowed.call
        else
          DeadCodeDetector.config.allowed
        end
      end

      private
      def descendants_of(parent_class)
        ObjectSpace.each_object(parent_class.singleton_class).select { |klass| klass < parent_class && klass.name }
      end

      def cache_methods_for(klass)
        class_wrapper = DeadCodeDetector::ClassMethodWrapper.new(klass)
        instance_wrapper = DeadCodeDetector::InstanceMethodWrapper.new(klass)
        if class_wrapper.number_of_tracked_methods + instance_wrapper.number_of_tracked_methods > 0
          MethodCacher.add_class(klass.name)
        end
        class_wrapper.populate_cache
        instance_wrapper.populate_cache
      end
    end

  end
end
