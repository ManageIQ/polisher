# Polisher Gemfile Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gemfile'

module Bundler
  describe "#gem" do
    it "stores parsed gems"
  end
end

module Polisher
  describe Gemfile do
    describe "#initialize" do
      it "sets gemfile deps,dev_deps" do
        gemfile = Polisher::Gemfile.new :deps => ['rails'], :dev_deps => ['rake']
        gemfile.deps.should == ['rails']
        gemfile.dev_deps.should == ['rake']
      end

      it "sets default gemfile version,files" do
        gemfile = Polisher::Gemfile.new
        gemfile.version.should be_nil
        gemfile.file_paths.should == []
      end
    end

    describe "#parse" do
      it "returns new gemfile instance" do
        gemfile = Polisher::Test::GEMFILE
        pgemfile = Polisher::Gemfile.parse gemfile[:path]
        pgemfile.should be_an_instance_of(Polisher::Gemfile)
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
