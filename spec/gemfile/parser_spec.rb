# Polisher Gemfile Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gemfile'

module Polisher
  describe Gemfile do
    describe "#parse" do
      it "returns new gemfile instance" do
        gemfile = Polisher::Test::GEMFILE
        pgemfile = Polisher::Gemfile.parse gemfile[:path]
        pgemfile.should be_an_instance_of(Polisher::Gemfile)
        pgemfile.definition.should be_an_instance_of(Bundler::Definition)
      end

      it "parses deps,dev_deps from spec" do
        gemfile = Polisher::Test::GEMFILE
        pgemfile = Polisher::Gemfile.parse gemfile[:path]
        pgemfile.deps.should == gemfile[:deps]
        #pgemfile.dev_deps.should...
      end
    end
  end # describe Gemfile
end # module Polisher
