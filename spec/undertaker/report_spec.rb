require "spec_helper"

RSpec.describe Undertaker::Report do
  class Undertaker::Report::TestClass
    def self.foo; end
  end

  class Undertaker::Report::TestClass2
    def bar; end
  end

  before do
    Undertaker::Initializer.refresh_cache_for(Undertaker::Report::TestClass)
    Undertaker::Initializer.refresh_cache_for(Undertaker::Report::TestClass2)
  end

  describe ".unused_methods" do
    subject { Undertaker::Report.unused_methods }

    it { is_expected.to include "Undertaker::Report::TestClass.foo" }
    it { is_expected.to include "Undertaker::Report::TestClass2#bar" }
  end

  describe ".unused_methods_for" do
    subject { Undertaker::Report.unused_methods_for(Undertaker::Report::TestClass2.name) }

    it { is_expected.to_not include "Undertaker::Report::TestClass.foo" }
    it { is_expected.to include "Undertaker::Report::TestClass2#bar" }
  end
end
