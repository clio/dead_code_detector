require "spec_helper"

RSpec.describe Undertaker do
  class Undertaker::TestClass
    def self.foo; end
  end

  describe ".enable" do
    before do
      Undertaker::Initializer.setup_for(Undertaker::TestClass)
    end

    it "tracks method calls inside of the block" do
      expect do
        Undertaker.enable do
          Undertaker::TestClass.foo
        end
      end.to change{ Undertaker::ClassMethodWrapper.new(Undertaker::TestClass).send(:potentially_unused_methods).include?("foo") }.from(true).to(false)

      expect(Undertaker.config.backend.pending_deletions).to be_empty
    end

    it "doesn't record method calls outside of the block" do
      Undertaker.enable {}
      Undertaker::TestClass.foo

      expect(Undertaker.config.backend.pending_deletions.values).to include(Set.new(["foo"]))
    end
  end
end
