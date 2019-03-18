module Undertaker
  class InstanceMethodWrapper < BaseMethodWrapper

    class << self
      def unwrap_method(klass, original_method)
        if original_method.owner == klass
          klass.send(:define_method, original_method.name, original_method)
        else
          klass.send(:remove_method, original_method.name)
        end
        track_method(klass, original_method.name)
      end

      def record_key(class_name)
        "undertaker/record_keeper/#{class_name}/instance_methods"
      end
    end

    def get_method(method_name)
      klass.instance_method(method_name)
    end

    private

    def wrap_method(original_method)
      original_class = klass
      klass.send(:define_method, original_method.name) do |*args, &block|
        begin
          Undertaker::InstanceMethodWrapper.unwrap_method(original_class, original_method)
        rescue StandardError => e
          if Undertaker.config.error_handler
            Undertaker.config.error_handler.call(e)
          end
        end
        method_bound_to_caller = original_method.bind(self)
        method_bound_to_caller.call(*args, &block)
      end
    end

    def default_methods
      klass.instance_methods.map(&:to_s).select{|method_name| owned_method?(method_name) }
    end

    def owned_method?(method_name)
      original_method = klass.instance_method(method_name)
      klass <= original_method.owner && !(klass.superclass <= original_method.owner)
    end

  end
end
