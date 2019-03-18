module Undertaker
  class Initializer

    class << self

      def refresh_caches
        Undertaker.config.classes_to_monitor.each do |klass|
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

      def enable(klass)
        Undertaker::ClassMethodWrapper.new(klass).wrap_methods!
        Undertaker::InstanceMethodWrapper.new(klass).wrap_methods!
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
        if Undertaker.config.allowed.respond_to?(:call)
          Undertaker.config.allowed.call
        else
          Undertaker.config.allowed
        end
      end

      def cached_classes
        Undertaker.config.storage.get(tracked_classes_key)
      end

      private
      def descendants_of(parent_class)
        ObjectSpace.each_object(parent_class.singleton_class).select { |klass| klass < parent_class }
      end

      def cache_methods_for(klass)
        Undertaker.config.storage.add(tracked_classes_key, klass.name)
        Undertaker::ClassMethodWrapper.new(klass).refresh_cache
        Undertaker::InstanceMethodWrapper.new(klass).refresh_cache
      end

      def tracked_classes_key
        "undertaker/method_wrapper/tracked_classes"
      end
    end

  end
end
