#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/pkg'

module Polisher
  describe Git::Pkg do
    describe "#update_metadata" do
      it "sets pkg version" do
        pkg = described_class.new
        pkg.update_metadata(Polisher::Gem.new(:version => '5.0'))
        pkg.version.should == '5.0'
      end
    end

    describe "#update_spec_to" do
      it "updates spec metadata"
      it "updates spec version"
      it "updates spec release"
    end

    describe "#gen_sources_for" do
      it "writes gem md5sum to sources file"
    end

    describe "#ignore" do
      it "adds gem to .gitignore file"
    end

    describe "#update_to" do
      it "updates rpm spec"
      it "generates new sources file"
      it "ignores gem"
    end

  end # describe Git::Pkg
end # module Polisher
