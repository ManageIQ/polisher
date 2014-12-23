#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "#requirements_for_gem" do
      it "returns requirements for specified gem name" do
        spec = described_class.new :requires =>
          [Requirement.new(:name => 'rubygem(rake)')]
        spec.requirements_for_gem('rake').should == [spec.requires.first]
      end

      context "spec has no requirement with specified name" do
        it "returns empty array" do
          spec = described_class.new
          spec.requirements_for_gem('rake').should be_empty
        end
      end
    end

    describe "#build_requirements_for_gem" do
      it "returns build requirements for specified gem name" do
        spec = described_class.new :build_requires => [Requirement.new(:name => 'rubygem(rake)')]
        spec.build_requirements_for_gem('rake').should == [spec.build_requires.first]
      end

      context "spec has no requirement with specified name" do
        it "returns empty array" do
          spec = described_class.new
          spec.build_requirements_for_gem('rake').should be_empty
        end
      end
    end
  end # describe Spec
end # module Polisher::RPM
