#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "::parse" do
      it "returns new gem" do
        gem = described_class.parse
        gem.should be_an_instance_of(described_class)
      end

      it "parses gem from gem spec" do
        spec = Polisher::Test::GEM_SPEC
        gem  = described_class.parse(:gemspec => spec[:path])
        gem.name.should     == spec[:name]
        gem.version.should  == spec[:version]
        gem.deps.should     == spec[:deps]
        gem.dev_deps.should == spec[:dev_deps]
      end

      it "parses gem from gem at path" do
        spec = Polisher::Test::GEM_SPEC
        pkg = ::Gem::Package.new('path')
        ::Gem::Package.should_receive(:new).with('path').and_return(pkg)
        pkg.should_receive(:spec).and_return(spec[:path])

        gem = described_class.parse :gem => 'path'
        gem.name.should == spec[:name]
        gem.path.should == 'path'
      end

      it "parses gem from metadata hash" do
        gem = described_class.parse gem_json[:json]
        gem.name.should     == gem_json[:name]
        gem.version.should  == gem_json[:version]
        gem.deps.should     == gem_json[:deps]
        gem.dev_deps.should == gem_json[:dev_deps]
      end
    end
  end # describe Gem
end # module Polisher
