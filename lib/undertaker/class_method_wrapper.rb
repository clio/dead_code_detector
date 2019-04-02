module Undertaker
  class ClassMethodWrapper < BaseMethodWrapper

    class << self
      def unwrap_method(klass, original_method)
        if klass.singleton_class == original_method.owner
          klass.define_singleton_method(original_method.name, original_method)
        else
          klass.singleton_class.send(:remove_method, original_method.name)
        end
        track_method(klass, original_method.name)
      end

      def record_key(class_name)
        "undertaker/record_keeper/#{class_name}/class_methods"
      end
    end

    def get_method(method_name)
      klass.method(method_name)
    end

    private

    def wrap_method(original_method)
      original_class = klass
      klass.define_singleton_method(original_method.name) do |*args, &block|
        begin
          Undertaker::ClassMethodWrapper.unwrap_method(original_class, original_method)
        rescue StandardError => e
          if Undertaker.config.error_handler
            Undertaker.config.error_handler.call(e)
          end
        end
        # We may have a method like `ActiveRecord::Base.sti_name`
        # that begins bound to `ActiveRecord::Base`
        # However, it may be called from `User.sti_name`
        # We need to bind the original method to the class that
        # is calling the method
        unbound_method = original_method.unbind
        method_bound_to_caller = unbound_method.bind(self)
        method_bound_to_caller.call(*args, &block)
      end
    end

    def default_methods
      klass.methods.map(&:to_s).select do |method_name|
        owned_method?(method_name) && target_directory?(method_name)
      end
    end

    def target_directory?(method_name)
      return true if Undertaker.config.ignore_paths.nil?
      source_location = klass.method(method_name).source_location&.first
      source_location !~ Undertaker.config.ignore_paths
    end

    def owned_method?(method_name)
      original_method = klass.method(method_name)
      klass.singleton_class <= original_method.owner && !(klass.superclass.singleton_class <= original_method.owner)
    end

  end
end
