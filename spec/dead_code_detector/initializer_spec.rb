require "spec_helper"

RSpec.describe DeadCodeDetector::Initializer do
  let(:anonymous_class) do
    Class.new do
      def self.name
        @name ||= "AnonymousClass-#{object_id}"
      end
    end
  end

  describe ".allowed?" do
    before do
      count = 0
      allow(DeadCodeDetector.config).to receive(:allowed).and_return(->{
        count += 1
        count == 1
      })
    end
    it "is true for the first call and false for all subsequent calls" do
      expect(described_class).to be_allowed
      expect(described_class).to_not be_allowed
    end
  end

  describe ".refresh_cache_for" do
    it "marks the class as being tracked" do
      expect do
        described_class.refresh_cache_for(anonymous_class)
      end.to change{ DeadCodeDetector::Initializer.cached_classes.include?(anonymous_class.name) }
        .from(false)
        .to(true)
    end

    context "when the class has no tracked methods" do
      let(:anonymous_class) { Class.new }
      it "doesn't include it in the cached classes" do
        expect do
          described_class.refresh_cache_for(anonymous_class)
        end.to_not change{ DeadCodeDetector::Initializer.cached_classes }
      end
    end
  end

  describe ".enable_for_cached_classes!" do
    context "when the process takes longer than the max" do
      before do
        allow(DeadCodeDetector::Initializer).to receive(:cached_classes).and_return([anonymous_class.name])
        allow(DeadCodeDetector.config).to receive(:allowed).and_return(true)
        allow(DeadCodeDetector.config).to receive(:max_seconds_to_enable).and_return(-1)
      end

      after do
        DeadCodeDetector::Initializer.fully_enabled = nil
        DeadCodeDetector::Initializer.last_enabled_class = nil
      end

      it "stops when it hits the cutoff" do
        expect(DeadCodeDetector::Initializer.fully_enabled).to be_falsey

        DeadCodeDetector::Initializer.enable_for_cached_classes!

        expect(DeadCodeDetector::Initializer.fully_enabled).to be_falsey
        expect(DeadCodeDetector::Initializer.last_enabled_class).to eql anonymous_class.name
      end

      it "restarts from the last_enabled_class" do
        expect(DeadCodeDetector::Initializer.fully_enabled).to be_falsey
        DeadCodeDetector::Initializer.last_enabled_class = anonymous_class.name

        DeadCodeDetector::Initializer.enable_for_cached_classes!
        expect(DeadCodeDetector::Initializer.fully_enabled).to be_truthy
      end
    end
  end

  describe ".enable" do
    before do
      described_class.refresh_cache_for(anonymous_class)
    end

    it "wraps the class methods" do
      wrapper = double
      expect(DeadCodeDetector::ClassMethodWrapper).to receive(:new).with(anonymous_class).and_return(wrapper)
      expect(wrapper).to receive(:wrap_methods!)
      described_class.enable(anonymous_class)
    end

    it "wraps the instance methods" do
      wrapper = double
      expect(DeadCodeDetector::InstanceMethodWrapper).to receive(:new).with(anonymous_class).and_return(wrapper)
      expect(wrapper).to receive(:wrap_methods!)
      described_class.enable(anonymous_class)
    end
  end
end
