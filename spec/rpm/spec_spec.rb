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

      context "metadata key not set" do
        it "returns nil" do
          spec = described_class.new
          spec.version.should be_nil
        end
      end

      it "sets metadata" do
        spec = described_class.new
        spec.version = '1.0'
        spec.version.should == '1.0'
        spec.metadata[:version].should == '1.0'
      end

      context "method not a metadata key" do
        it "dispatches to super" do
          lambda{
            described_class.new.foo
          }.should raise_error
        end
      end
    end

    describe "#to_string" do
      it "returns string representation of spec" do
        spec = described_class.new :contents => 'contents'
        spec.to_string.should == "contents"
      end
    end

    describe "#length" do
      it "returns the length of spec contents" do
        spec = described_class.new :contents => 'contents'
        spec.length.should == 8
      end
    end
  end # describe Spec
end # module Polisher::RPM
