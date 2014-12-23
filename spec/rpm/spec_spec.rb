# Polisher RPM Spec Specs
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'
require 'polisher/gem'

module Polisher::RPM
  describe Spec do
    describe "#initialize" do
      it "sets gem metadata" do
        spec = described_class.new :version => '1.0.0'
        spec.metadata.should == described_class.default_metadata.merge(:version => '1.0.0')
      end
    end

    describe "#method_missing" do
      it "proxies lookup to metadata" do
        spec = described_class.new :version => '1.0.0'
        spec.version.should == '1.0.0'
      end
    end

    describe "#to_string" do
      it "returns string representation of spec"
    end
  end # describe Spec
end # module Polisher::RPM
