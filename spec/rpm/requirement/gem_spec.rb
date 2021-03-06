#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'
require 'polisher/rpm/requirement'

module Polisher::RPM
  describe Requirement do
    describe "::from_gem_dep" do
      it "returns new requirements corresponding to gem dependency" do
        dep = ::Gem::Dependency.new 'rails', '~> 4.0.0'
        expected = [described_class.new(:name      => 'rubygem(rails)',
                                        :condition => '=>',
                                        :version   => '4.0.0'),
                    described_class.new(:name      => 'rubygem(rails)',
                                        :condition => '<',
                                        :version   => '4.1')]
        described_class.from_gem_dep(dep).should == expected
      end
    end

    describe "#gem?" do
      context "requirement matches gem dep matcher" do
        it "returns true" do
          described_class.parse("rubygem(rails)").gem?.should be_true
        end
      end

      context "requirement does not match gem dep matcher" do
        it "returns false" do
          described_class.parse("something").gem?.should be_false
        end
      end
    end

    describe "#gem_name" do
      it "returns gem name" do
        described_class.parse("rubygem(rails)").gem_name.should == "rails"
      end

      context "requirement is not a gem" do
        it "returns nil" do
          described_class.parse("something").gem_name.should be_nil
        end
      end
    end
  end # describe Requirement
end # module Polisher::RPM
