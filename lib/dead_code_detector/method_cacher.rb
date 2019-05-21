module DeadCodeDetector
  class MethodCacher

    class << self
      def cached_classes
        internal_mapping.keys
      end

      def clear_cache
        @internal_mapping = nil
        @method_mapping = nil
        @count = 0
        DeadCodeDetector.config.storage.clear(tracked_classes_key)
        DeadCodeDetector.config.storage.clear(tracked_methods_key)
      end

      def add_class(class_name)
        @count ||= 0
        @count += 1
        DeadCodeDetector.config.storage.add(tracked_classes_key, "#{class_name}&#{@count}")
        internal_mapping[class_name] = @count
      end

      def track_method(class_name, method_name, delimiter:)
        tracked_method_name = "#{class_identifier(class_name)}#{delimiter}#{method_name}"
        DeadCodeDetector.config.storage.delete(
          tracked_methods_key, tracked_method_name
        )
        method_mapping[class_identifier(class_name)][delimiter].delete(method_name.to_s)
      end

      def populate_method_cache(class_name, methods, delimiter:)
        delimited_methods = methods.map do |method_name|
          "#{class_identifier(class_name)}#{delimiter}#{method_name}"
        end
        DeadCodeDetector.config.storage.add(class_name, delimited_methods)
        method_mapping[class_identifier(class_name)][delimiter] = Set.new(methods)
      end

      def potentially_unused_methods(class_name, delimiter:)
        method_mapping[class_identifier(class_name)][delimiter] || Set.new
      end

      private
      def class_identifier(class_name)
        internal_mapping.fetch(class_name)
      end

      def tracked_classes_key
        "dead_code_detector/method_cacher/tracked_classes"
      end

      def tracked_methods_key
        "dead_code_detector/method_cacher/methods"
      end

      def method_mapping
        return @method_mapping if @method_mapping
        @method_mapping = Hash.new{|h,k| h[k] = {} }
        DeadCodeDetector.config.storage.get(tracked_methods_key).map do |name|
          match = name.match(/(?<class_identifier>\d+)(?<delimiter>\W)(?<method_name>.*)/)
          @method_mamping[method[:class_identifier]][match[:delimiter]] ||= Set.new
          @method_mamping[method[:class_identifier]][match[:delimiter]] << match[:method_name]
        end
        @method_mapping
      end

      def internal_mapping
        @internal_mapping ||= DeadCodeDetector.config.storage.get(tracked_classes_key).map do |name|
          name.split("&")
        end.to_h
      end

    end
  end
end
