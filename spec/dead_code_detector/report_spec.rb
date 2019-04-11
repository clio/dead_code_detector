require "spec_helper"

RSpec.describe DeadCodeDetector::Report do
  class DeadCodeDetector::Report::TestClass
    def self.foo; end
  end

  class DeadCodeDetector::Report::TestClass2
    def bar; end
  end

  before do
    DeadCodeDetector::Initializer.refresh_cache_for(DeadCodeDetector::Report::TestClass)
    DeadCodeDetector::Initializer.refresh_cache_for(DeadCodeDetector::Report::TestClass2)
  end

  describe ".unused_methods" do
    subject { DeadCodeDetector::Report.unused_methods }

    it { is_expected.to include "DeadCodeDetector::Report::TestClass.foo" }
    it { is_expected.to include "DeadCodeDetector::Report::TestClass2#bar" }
  end

  describe ".unused_methods_for" do
    subject { DeadCodeDetector::Report.unused_methods_for(DeadCodeDetector::Report::TestClass2.name) }

    it { is_expected.to_not include "DeadCodeDetector::Report::TestClass.foo" }
    it { is_expected.to include "DeadCodeDetector::Report::TestClass2#bar" }
  end
end
