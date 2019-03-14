module Undertaker
  class Initializer

    class << self

      def setup_all
        Undertaker.config.tracked_classes.each do |klass|
          setup_for(klass)
        end
      end

      def setup_for(klass)
        @enabled = false
        classes = [klass, *descendants_of(klass)]
        classes.each do |class_to_enable|
          track_class(class_to_enable)
          Undertaker::ClassMethodWrapper.new(class_to_enable).refresh_cache
          Undertaker::InstanceMethodWrapper.new(class_to_enable).refresh_cache
        end
      end

      def enable(klass)
        Undertaker::ClassMethodWrapper.new(klass).wrap_methods!
        Undertaker::InstanceMethodWrapper.new(klass).wrap_methods!
      end

      def enable_for_tracked_classes!
        return if @enabled
        return unless allowed?
        @enabled = true
        tracked_classes.each do |class_name|
          klass = Object.const_get(class_name) rescue nil
          enable(klass) if klass
        end
      end

      def allowed?
        return true unless Undertaker.config.redis
        key = "#{self.name}/lock"
        (Undertaker.config.redis.incr(key) == 1).tap do |is_first|
          Undertaker.config.redis.expire(key, 60) if is_first
        end
      end

      def tracked_classes
        Undertaker.config.backend.get(tracked_classes_key)
      end

      private
      def descendants_of(parent_class)
        ObjectSpace.each_object(parent_class.singleton_class).select { |klass| klass < parent_class }
      end

      def track_class(klass)
        Undertaker.config.backend.add(tracked_classes_key, klass.name)
      end

      def tracked_classes_key
        "undertaker/method_wrapper/tracked_classes"
      end
    end

  end
end
