#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "#parse" do
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

      it "parses gem from gem at path"

      it "parses gem from metadata hash" do
        gemj = Polisher::Test::GEM_JSON
        gem = described_class.parse gemj[:json]
        gem.name.should     == gemj[:name]
        gem.version.should  == gemj[:version]
        gem.deps.should     == gemj[:deps]
        gem.dev_deps.should == gemj[:dev_deps]
      end
    end

  end # describe Gem
end # module Polisher
