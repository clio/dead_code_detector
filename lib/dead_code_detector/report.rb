module DeadCodeDetector
  class Report

    class << self

      def unused_methods
        MethodCacher.cached_classes.flat_map do |class_name|
          unused_methods_for(class_name)
        end
      end

      def unused_methods_for(class_name)
        methods = []
        unused_class_methods_for(class_name).each_with_object(methods) do |method_name, collection|
          collection << "#{class_name}.#{method_name}"
        end
        unused_instance_methods_for(class_name).each_with_object(methods) do |method_name, collection|
          collection << "#{class_name}##{method_name}"
        end
        methods
      end

      private
      def unused_class_methods_for(class_name)
        MethodCacher.potentially_unused_methods(class_name, delimiter: ClassMethodWrapper.delimiter)
      end

      def unused_instance_methods_for(class_name)
        MethodCacher.potentially_unused_methods(class_name, delimiter: InstanceMethodWrapper.delimiter)
      end
    end

  end
end
