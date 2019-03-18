require "undertaker/version"
require "undertaker/base_method_wrapper"
require "undertaker/class_method_wrapper"
require "undertaker/instance_method_wrapper"
require "undertaker/storage"
require "undertaker/initializer"
require "undertaker/configuration"

module Undertaker

  def self.configure(&block)
    block.call(config)
  end

  def self.config
    @config ||= Undertaker::Configuration.new
  end

  def self.enable(&block)
    Undertaker::Initializer.enable_for_cached_classes!
    block.call
    config.storage.flush
  end

end
