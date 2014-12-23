#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/pkg'

module Polisher
  describe Git::Pkg do
    describe "#initialize" do
      it "initializes name" do
        pkg = described_class.new :name => 'pkg_name'
        pkg.name.should == 'pkg_name'
      end

      it "initializes version" do
        pkg = described_class.new :version => 'pkg_version'
        pkg.version.should == 'pkg_version'
      end
    end
  end # describe Git::Pkg
end # module Polisher
