# Polisher RPMSpec Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'spec_helper'

require 'polisher/rpmspec'
require 'polisher/gem'

module Polisher
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
  end # describe RPMSpec
end # module Polisher
