# Polisher Bodhi Spec
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'polisher/bodhi'

module Polisher
  describe Bodhi do
    describe "#versions_for" do
      before(:each) do
      end

      it "uses pkgwat to retreive updates" do
        Pkgwat.should_receive(:get_updates).with("rubygem-rails", "all", "all").and_return([])
        described_class.versions_for "rails"
      end

      it "returns versions" do
        Pkgwat.should_receive(:get_updates).and_return([{'stable_version' => '1.0.0'}])
        described_class.versions_for("rails").should == ['1.0.0']
      end

      it "invokes block with versions" do
        cb = proc {}
        cb.should_receive(:call).with(:bodhi, 'rails', ['1.0.0'])
        Pkgwat.should_receive(:get_updates).and_return([{'stable_version' => '1.0.0'}])
        described_class.versions_for("rails", &cb)
      end
    end
  end # describe Koji
end # module Polisher
