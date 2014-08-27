# Polisher VersionedDependencies Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/version_checker'

module Polisher
  describe VersionedDependencies do
    before(:each) do
      @obj = Object.new
      @obj.extend(VersionedDependencies)
    end

    describe "#dependency_versions" do
      it "returns versions of all dependencies" do
        bl = proc {}

        dep1 = ::Gem::Dependency.new 'dep1'
        dep2 = ::Gem::Dependency.new 'dep2'
        @obj.should_receive(:deps).and_return([dep1, dep2])

        gem1 = Polisher::Gem.new
        gem2 = Polisher::Gem.new
        Polisher::Gem.should_receive(:retrieve).with('dep1').and_return(gem1)
        Polisher::Gem.should_receive(:retrieve).with('dep2').and_return(gem2)

        default_args = {:recursive => true, :dev_deps => true}

        versions1 = {:dep1 => {:koji => ['1.0.1']}}
        gem1.should_receive(:versions).with(default_args, &bl).and_return(versions1)

        versions2 = {:dep2 => {:koji => ['2.0.0']}}
        gem2.should_receive(:versions).with(default_args, &bl).and_return(versions2)

        combined = versions1.merge versions2

        @obj.dependency_versions(&bl).should == combined
      end
    end

    describe "#dependency_states" do
      it "returns states of all dependencies" do
        dep1 = ::Gem::Dependency.new 'dep1'
        dep2 = ::Gem::Dependency.new 'dep2'
        @obj.should_receive(:deps).and_return([dep1, dep2])

        gem1 = Polisher::Gem.new
        gem2 = Polisher::Gem.new
        Polisher::Gem.should_receive(:new).with(:name => 'dep1').and_return(gem1)
        Polisher::Gem.should_receive(:new).with(:name => 'dep2').and_return(gem2)

        gem1.should_receive(:state).with(:check => dep1).and_return('built')
        gem2.should_receive(:state).with(:check => dep2).and_return('missing')

        @obj.dependency_states.should == {'dep1' => 'built', 'dep2' => 'missing'}
      end
    end

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
