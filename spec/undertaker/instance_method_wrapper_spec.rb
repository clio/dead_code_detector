require "spec_helper"

RSpec.describe Undertaker::InstanceMethodWrapper do

  let(:anonymous_class) do
    Class.new do
      def self.name
        @name ||= "AnonymousClass-#{object_id}"
      end

      def counter=(val)
        @counter = val
      end

      def counter
        @counter ||= 0
      end

      def bar
        self.counter ||= 0
        self.counter += 1
      end
    end
  end

  before do
    Undertaker::Initializer.refresh_cache_for(anonymous_class)
  end

  describe "#wrap_methods!" do
    it "wraps methods defined in the class" do
      expect do
        described_class.new(anonymous_class).wrap_methods!
      end.to change{ anonymous_class.instance_method(:bar).source_location }
    end

    it "doesn't wrap methods it inherits but doesn't redefine" do
      expect do
        described_class.new(anonymous_class).wrap_methods!
      end.to_not change{ anonymous_class.instance_method(:object_id).source_location }
    end
  end

  context ".refresh_cache" do
    before do
      Undertaker.config.storage.clear(described_class.record_key(anonymous_class.name))
    end


    context "when there is a ignore_paths set" do
      context "and it doesn't match the source location" do
        around(:each) do |example|
          begin
            old_path = Undertaker.config.ignore_paths
            Undertaker.config.ignore_paths = /foo/
            example.run
          ensure
            Undertaker.config.ignore_paths = old_path
          end
        end

        it "includes the methods" do
          expect do
            described_class.new(anonymous_class).refresh_cache
          end.to change{ Undertaker.config.storage.get(described_class.record_key(anonymous_class.name)) }
            .from(Set.new)
            .to(Set.new(["bar", "counter", "counter="]))
        end
      end

      context "and it matches the source location" do
        around(:each) do |example|
          begin
            old_path = Undertaker.config.ignore_paths
            Undertaker.config.ignore_paths = /spec/
            example.run
          ensure
            Undertaker.config.ignore_paths = old_path
          end
        end

        it "doesn't includes the methods" do
          expect do
            described_class.new(anonymous_class).refresh_cache
          end.to_not change{ Undertaker.config.storage.get(described_class.record_key(anonymous_class.name)) }
        end
      end

    end

    it "sets up the cache with the full list of methods" do
      expect do
        described_class.new(anonymous_class).refresh_cache
      end.to change{ Undertaker.config.storage.get(described_class.record_key(anonymous_class.name)) }
        .from(Set.new)
        .to(Set.new(["bar", "counter", "counter="]))
    end

    context "when the class contains methods from a module" do
      let(:anonymous_class) do
        m = Module.new do
          def bar
            self.counter ||= 0
            self.counter += 1
          end
        end

        Class.new do
          include m

          def counter=(val)
            @counter = val
          end

          def counter
            @counter ||= 0
          end
          def self.name
            @name ||= "AnonymousClass-#{object_id}"
          end
        end
      end

      context "and the module is include in the parent" do
        let(:second_anonymous_class) do
          Class.new(anonymous_class)
        end

        it "does not include the module method" do
          expect do
            described_class.new(second_anonymous_class).refresh_cache
          end.to_not change{  Undertaker.config.storage.get(described_class.record_key(second_anonymous_class.name)).include?("bar") }
        end
      end

      it "includes the module method" do
        expect do
          described_class.new(anonymous_class).refresh_cache
        end.to change{  Undertaker.config.storage.get(described_class.record_key(anonymous_class.name)).include?("bar") }
          .from(false)
          .to(true)

      end
    end

  end

  context "when a wrapped method is called" do

    it "marks the method as being used" do
      wrapper = described_class.new(anonymous_class)
      wrapper.wrap_methods!

      expect do
        anonymous_class.new.bar
      end.to change { Undertaker::Report.unused_methods_for(anonymous_class.name).include?("#{anonymous_class.name}#bar") }
        .from(true)
        .to(false)
    end

    it "removes the wrapper" do
      original_source_location = anonymous_class.instance_method(:bar).source_location
      described_class.new(anonymous_class).wrap_methods!
      wrapped_source_location = anonymous_class.instance_method(:bar).source_location

      expect do
        anonymous_class.new.bar
      end.to change { anonymous_class.instance_method(:bar).source_location }
        .from(wrapped_source_location)
        .to(original_source_location)
    end

    context "and the method is from a module and uses super" do
      let(:second_anonymous_class) do
        m = Module.new do
          def bar
            self.counter ||= 0
            self.counter += 1
            super
          end
        end

        Class.new(anonymous_class) do
          include m
        end
      end

      before do
        Undertaker::Initializer.refresh_cache_for(second_anonymous_class)
        wrapper = described_class.new(second_anonymous_class)
        wrapper.wrap_methods!
      end

      it "calls the method on the module and the superclass when unwrapped" do
        instance = second_anonymous_class.new
        expect {
          instance.bar
        }.to change { instance.counter }.from(0).to(2)

        expect {
          instance.bar
        }.to change { instance.counter }.from(2).to(4)
      end
    end

    it "calls the original method" do
      described_class.new(anonymous_class).wrap_methods!
      instance = anonymous_class.new
      expect do
        instance.bar
      end.to change{ instance.counter }.from(0).to(1)
    end
  end
end
