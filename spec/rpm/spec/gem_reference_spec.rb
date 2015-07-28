#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'
require 'polisher/gem'

module Polisher::RPM
  describe Spec do
    let(:spec) { described_class.new }
    let(:gem)  { Polisher::Gem.new   }

    describe "#upstream_gem" do
      it "sets & returns upstream gem" do
        gem_name = 'polisher'
        version  = 5.0
        Polisher::Gem.should_receive(:from_rubygems)
                     .with(gem_name, version).and_return(gem)
        spec = described_class.new :gem_name => gem_name, :version => version
        spec.upstream_gem.should == gem
        spec.upstream_gem.object_id.should == spec.upstream_gem.object_id
      end
    end

    describe "#missing_deps_for" do
      it "returns gem deps without corresponding requirements" do
        gem.deps = local_gem.deps
        spec.should_receive(:requirements_for_gem)
            .with(gem.deps.first.name).and_return([])
        spec.should_receive(:requirements_for_gem)
            .exactly(gem.deps.length-1).times.and_return(['req'])
        spec.missing_deps_for(gem).should == [gem.deps.first]
      end
    end

    describe "#missing_dev_deps_for" do
      it "returns gem dev deps without corresponding build requirements" do
        gem.dev_deps = local_gem.deps
        spec.should_receive(:build_requirements_for_gem)
            .with(gem.dev_deps.first.name).and_return([])
        spec.should_receive(:build_requirements_for_gem)
            .exactly(gem.dev_deps.length-1).times.and_return(['req'])
        spec.missing_dev_deps_for(gem).should == [gem.dev_deps.first]
      end
    end

    describe "#excluded_deps" do
      it "returns missing deps for upstream gem" do
        expected = ['deps']
        spec.gem = gem
        spec.should_receive(:missing_deps_for).with(gem).and_return(expected)
        spec.excluded_deps.should == expected
      end
    end

    describe "#excludes_dep?" do
      context "upstream gem excludes specified gem" do
        it "returns true" do
          deps = [::Gem::Dependency.new('rails')]
          spec.should_receive(:excluded_deps).and_return(deps)
          spec.excludes_dep?('rails').should be_true
        end
      end

      context "upstream gem does not exclude specified gem" do
        it "returns false" do
          spec.should_receive(:excluded_deps).and_return([])
          spec.excludes_dep?('rails').should be_false
        end
      end
    end

    describe "#excluded_dev_deps" do
      it "returns missing dev deps for upstream gem" do
        expected = ['deps']
        spec.gem = gem
        spec.should_receive(:missing_dev_deps_for).with(gem).and_return(expected)
        spec.excluded_dev_deps.should == expected
      end
    end

    describe "#excludes_dev_dep?" do
      context "upstream gem excludes specified gem from dev deps" do
        it "returns true" do
          deps = [::Gem::Dependency.new('rails')]
          spec.should_receive(:excluded_dev_deps).and_return(deps)
          spec.excludes_dev_dep?('rails').should be_true
        end
      end

      context "upstream gem does not exclude specified gem from dev deps" do
        it "returns false" do
          spec.should_receive(:excluded_dev_deps).and_return([])
          spec.excludes_dev_dep?('rails').should be_false
        end
      end
    end
  end # describe Spec
end # module Polisher::RPM
