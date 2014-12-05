# Polisher VersionedDependencies Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/mixins/versioned_dependencies'

module Polisher
  describe VersionedDependencies do
    before(:each) do
      @obj = Object.new
      @obj.extend(VersionedDependencies)
    end

    it "retrieves versions of each dependency in configured targets"
    it "invokes block with targets / versions"

    describe "#dependency_for" do
      it "returns dependency w/ the specified name" do
        dep1 = ::Gem::Dependency.new 'dep1'
        dep2 = ::Gem::Dependency.new 'dep2'
        @obj.should_receive(:deps).twice.and_return([dep1, dep2])
        @obj.dependency_for('dep1').should == dep1
        @obj.dependency_for('dep2').should == dep2
      end
    end

    describe "#missing_dependencies" do
      it "returns dependencies with no matching target versions"
    end

    describe "#dependencies_satisfied?" do
      context "no missing dependencies" do
        it "returns true" do
          @obj.should_receive(:missing_dependencies).and_return([])
          @obj.dependencies_satisfied?.should be_true
        end
      end

      context "missing dependencies found" do
        it "returns false" do
          @obj.should_receive(:missing_dependencies).and_return(['rails'])
          @obj.dependencies_satisfied?.should be_false
        end
      end
    end
  end # described VersionedDependencies
end # module Polisher
