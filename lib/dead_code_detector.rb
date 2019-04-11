require "dead_code_detector/version"
require "dead_code_detector/base_method_wrapper"
require "dead_code_detector/class_method_wrapper"
require "dead_code_detector/instance_method_wrapper"
require "dead_code_detector/storage"
require "dead_code_detector/initializer"
require "dead_code_detector/configuration"
require "dead_code_detector/report"

module DeadCodeDetector

  def self.configure(&block)
    block.call(config)
  end

  def self.config
    @config ||= DeadCodeDetector::Configuration.new
  end

  def self.enable(&block)
    begin
      DeadCodeDetector::Initializer.enable_for_cached_classes!
      block.call
    ensure
      config.storage.flush
    end
  end

end
