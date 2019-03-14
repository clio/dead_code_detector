module Undertaker
  class ClassMethodWrapper < BaseMethodWrapper

    class << self
      def unwrap_method(klass, original_method)
        if klass.singleton_class == original_method.owner
          klass.class_eval do
            define_singleton_method(original_method.name, original_method)
          end
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
      original_class.class_eval do
        define_singleton_method(original_method.name) do |*args, &block|
          begin
            Undertaker::ClassMethodWrapper.unwrap_method(original_class, original_method)
          rescue StandardError => e
            if Undertaker.config.error_handler
              Undertaker.config.error_handler.call(e)
            end
          end
          # We may have a method like `ApplicationRecord.sti_name`
          # that begins bound to `ApplicationRecord`
          # However, it may be called from `Matter.sti_name`
          # We need to bind the original method to the class that
          # is calling the method
          unbound_method = original_method.unbind
          method_bound_to_caller = unbound_method.bind(self)
          method_bound_to_caller.call(*args, &block)
        end
      end
    end

    def default_methods
      klass.methods.map(&:to_s).select{|method_name| owned_method?(method_name) }
    end

    def owned_method?(method_name)
      original_method = klass.method(method_name)
      klass.singleton_class <= original_method.owner && !(klass.superclass.singleton_class <= original_method.owner)
    end

  end
end
