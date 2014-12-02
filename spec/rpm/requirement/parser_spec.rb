#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/requirement'

module Polisher::RPM
  describe Requirement do
    describe "#parse" do
      it "parses requirement string" do
        req = described_class.parse "Requires: rubygem(foo)"
        req.br.should be_false
        req.name.should == "rubygem(foo)"
        req.gem_name.should == "foo"
        req.condition.should be_nil
        req.version.should be_nil

        req = described_class.parse "BuildRequires: rubygem(foo)"
        req.br.should be_true

        req = described_class.parse "rubygem(rake)"
        req.br.should be_false
        req.name.should == "rubygem(rake)"

        req = described_class.parse "rubygem(rake) < 5"
        req.condition.should == "<"
        req.version.should == "5"
      end
    end
  end # describe Requirement
end # module Polisher::RPM
