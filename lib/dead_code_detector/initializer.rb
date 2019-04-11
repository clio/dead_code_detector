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
        cached_classes.each do |class_name|
          klass = Object.const_get(class_name) rescue nil
          if klass
            DeadCodeDetector::ClassMethodWrapper.new(klass).clear_cache
            DeadCodeDetector::InstanceMethodWrapper.new(klass).clear_cache
          end
        end
        DeadCodeDetector.config.storage.clear(tracked_classes_key)
      end

      def enable(klass)
        DeadCodeDetector::ClassMethodWrapper.new(klass).wrap_methods!
        DeadCodeDetector::InstanceMethodWrapper.new(klass).wrap_methods!
      end

      def enable_for_cached_classes!
        return if @enabled
        return unless allowed?
        @enabled = true
        cached_classes.each do |class_name|
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

      def cached_classes
        DeadCodeDetector.config.storage.get(tracked_classes_key)
      end

      private
      def descendants_of(parent_class)
        ObjectSpace.each_object(parent_class.singleton_class).select { |klass| klass < parent_class }
      end

      def cache_methods_for(klass)
        DeadCodeDetector.config.storage.add(tracked_classes_key, klass.name)
        DeadCodeDetector::ClassMethodWrapper.new(klass).refresh_cache
        DeadCodeDetector::InstanceMethodWrapper.new(klass).refresh_cache
      end

      def tracked_classes_key
        "dead_code_detector/method_wrapper/tracked_classes"
      end
    end

  end
end
