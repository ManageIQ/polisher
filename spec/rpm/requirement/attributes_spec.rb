#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/requirement'

module Polisher::RPM
  describe Requirement do
    describe "#str" do
      it "returns requirement in string format" do
        req = described_class.new :name => 'rubygem(activesupport)'
        req.str.should == 'rubygem(activesupport)'

        req = described_class.new :name => 'rubygem(activesupport)',
                                  :condition => '>=', :version => '4.0'
        req.str.should == 'rubygem(activesupport) >= 4.0'
      end
    end

    describe "#specifier" do
      it "returns specifier in string format" do
        req = described_class.new :condition => '>=', :version => '10.0'
        req.specifier.should == '>= 10.0'
      end

      context "version is nil" do
        it "returns nil" do
          req = described_class.new
          req.specifier.should be_nil
        end
      end
    end
  end # describe Requirement
end # module Polisher::RPM
