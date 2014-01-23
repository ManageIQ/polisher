# Polisher RPMSpec Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'spec_helper'

require 'polisher/rpmspec'
require 'polisher/gem'

module Polisher
  describe RPMSpec::Requirement do
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

    describe "#==" do
      context "requirements are equal" do
        it "returns true" do
          req1 = described_class.new
          req2 = described_class.new
          req1.should == req2

          req1 = described_class.parse 'rubygem(rails)'
          req2 = described_class.parse 'rubygem(rails)'
          req1.should == req2

          req1 = described_class.parse 'rubygem(rails) >= 1.0.0'
          req2 = described_class.parse 'rubygem(rails) >= 1.0.0'
          req1.should == req2
        end
      end

      context "requirements are not equal" do
        it "returns true" do
          req1 = described_class.parse 'rubygem(rails)'
          req2 = described_class.parse 'rubygem(rake)'
          req1.should_not == req2

          req1 = described_class.parse 'rubygem(rake) > 1'
          req2 = described_class.parse 'rubygem(rake) > 2'
          req1.should_not == req2
        end
      end
    end

    describe "#matches?" do
      context "requirement is same as dep requirement" do
        it "returns true"
      end

      context "requirement is not same as dep requirement" do
        it "returns false"
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
  end

  describe RPMSpec do
    describe "#initialize" do
      it "sets gem metadata" do
        spec = Polisher::RPMSpec.new :version => '1.0.0'
        spec.metadata.should == {:version => '1.0.0'}
      end
    end

    describe "#method_missing" do
      it "proxies lookup to metadata" do
        spec = Polisher::RPMSpec.new :version => '1.0.0'
        spec.version.should == '1.0.0'
      end
    end

    describe "#requirement_for_get" do
      it "returns requirement for specified gem name" do
        spec = Polisher::RPMSpec.new :requires =>
          [Polisher::RPMSpec::Requirement.new(:name => 'rubygem(rake)')]
        spec.requirement_for_gem('rake').should == spec.requires.first
      end

      context "spec has no requirement with specified name" do
        it "returns nil" do
          spec = Polisher::RPMSpec.new
          spec.requirement_for_gem('rake').should be_nil
        end
      end
    end

    describe "#parse" do
      before(:each) do
        @spec  = Polisher::Test::RPM_SPEC
      end

      it "returns new rpmspec instance" do
        pspec = Polisher::RPMSpec.parse @spec[:contents]
        pspec.should be_an_instance_of(Polisher::RPMSpec)
      end

      it "parses contents from spec" do
        pspec = Polisher::RPMSpec.parse @spec[:contents]
        pspec.contents.should == @spec[:contents]
      end

      it "parses name from spec" do
        pspec = Polisher::RPMSpec.parse @spec[:contents]
        pspec.gem_name.should == @spec[:name]
      end

      it "parses version from spec" do
        pspec = Polisher::RPMSpec.parse @spec[:contents]
        pspec.version.should == @spec[:version]
      end

      it "parses release from spec" do
        pspec = Polisher::RPMSpec.parse @spec[:contents]
        pspec.release.should == @spec[:release]
      end

      it "parses requires from spec" do
        pspec = Polisher::RPMSpec.parse @spec[:contents]
        pspec.requires.should == @spec[:requires]
      end

      it "parses build requires from spec" do
        pspec = Polisher::RPMSpec.parse @spec[:contents]
        pspec.build_requires.should == @spec[:build_requires]
      end

      it "parses changelog from spec"

      it "parses unrpmized files from spec" do
        pspec = Polisher::RPMSpec.parse @spec[:contents]
        pspec.files.should == @spec[:files]
      end
    end

    describe "#update_to" do
      it "updates dependencies from gem" do
        spec = Polisher::RPMSpec.new :requires => [Polisher::RPMSpec::Requirement.parse('rubygem(rake)'),
                                                   Polisher::RPMSpec::Requirement.parse('rubygem(activerecord)')],
                                     :build_requires => []
        gem  = Polisher::Gem.new :deps => [::Gem::Dependency.new('rake'),
                                           ::Gem::Dependency.new('rails', '~> 10')],
                                 :dev_deps => [::Gem::Dependency.new('rspec', :development)]

        spec.update_to(gem)
          spec.requires.should == [Polisher::RPMSpec::Requirement.parse('rubygem(activerecord)'),
                                   Polisher::RPMSpec::Requirement.parse('rubygem(rake) >= 0'),
                                   Polisher::RPMSpec::Requirement.parse('rubygem(rails) => 10'),
                                   Polisher::RPMSpec::Requirement.parse('rubygem(rails) < 11')]
        spec.build_requires.should == [Polisher::RPMSpec::Requirement.parse('rubygem(rspec) >= 0', :br => true)]
      end

      it "adds new files from gem" do
        spec = Polisher::RPMSpec.new :files => {'pkg' => ['/foo']}
        gem  = Polisher::Gem.new :files => ['/foo', '/foo/bar', '/baz']
        spec.update_to(gem)
        spec.new_files.should == ['/baz']
      end

      it "updates metadata from gem" do
        spec = Polisher::RPMSpec.new
        gem  = Polisher::Gem.new :version => '1.0.0'
        spec.update_to(gem)
        spec.version.should == '1.0.0'
        spec.release.should == '1%{?dist}'
      end

      it "adds changelog entry"
    end

    describe "#to_string" do
      it "returns string representation of spec"
    end

    describe "#compare" do
      it "returns requirements in spec but not in gem"
      it "returns requirements in gem but not in spec"
      it "returns shared requirements with different specifiers"
      it "returns shared requirements"
    end
  end # describe RPMSpec
end # module Polisher
