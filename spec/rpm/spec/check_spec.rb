#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "#has_check?" do
      context "package spec has %check section" do
        it "returns true" do
          spec = described_class.new :has_check => true
          spec.has_check?.should be_true
        end
      end

      context "package spec does not have a %check section" do
        it "returns false" do
          spec = described_class.new
          spec.has_check?.should be_false
        end
      end
    end
  end # describe Spec
end # module Polisher::RPM
