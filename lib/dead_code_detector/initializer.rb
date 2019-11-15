module DeadCodeDetector
  class Initializer

    class << self

      def refresh_caches
        DeadCodeDetector.config.classes_to_monitor.each do |klass|
          refresh_cache_for(klass)
        end
      end

      def refresh_cache_for(klass)
        @fully_enabled = false
        @last_enabled_class = nil
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
        return if @fully_enabled
        return unless allowed?
        classes = cached_classes.sort.to_a
        starting_index = classes.index(@last_enabled_class) || 0
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        classes[starting_index..-1].each do |class_name|
          klass = Object.const_get(class_name) rescue nil
          enable(klass) if klass
          @last_enabled_class = class_name
          return if Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time > DeadCodeDetector.config.max_seconds_to_enable
        end
        @fully_enabled = true
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
        ObjectSpace.each_object(parent_class.singleton_class).select do |klass|
          klass < parent_class && !klass.anonymous?
        end
      end

      def cache_methods_for(klass)
        class_wrapper = DeadCodeDetector::ClassMethodWrapper.new(klass).tap(&:refresh_cache)
        instance_wrapper = DeadCodeDetector::InstanceMethodWrapper.new(klass).tap(&:refresh_cache)
        if class_wrapper.number_of_tracked_methods + instance_wrapper.number_of_tracked_methods > 0
          DeadCodeDetector.config.storage.add(tracked_classes_key, klass.name)
        end
      end

      def tracked_classes_key
        "dead_code_detector/method_wrapper/tracked_classes"
      end
    end

  end
end
