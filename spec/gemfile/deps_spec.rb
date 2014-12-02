#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gemfile'

module Polisher
  describe Gemfile do
    describe "#vendored" do
      it "returns gemfile deps + dev_deps" do
        gemfile = described_class.new :deps => ['rails'], :dev_deps => ['rake']
        gemfile.vendored.should == ['rails', 'rake']
      end
    end

    describe "#patched" do
      it "..."
    end
  end # describe Gemfile
end # module Polisher
