#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "#parse" do
      before(:each) do
        @spec  = Polisher::Test::RPM_SPEC
      end

      it "returns new rpmspec instance" do
        pspec = described_class.parse @spec[:contents]
        pspec.should be_an_instance_of(described_class)
      end

      it "parses contents from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.contents.should == @spec[:contents]
      end

      it "parses name from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.gem_name.should == @spec[:name]
      end

      it "parses version from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.version.should == @spec[:version]
      end

      it "parses release from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.release.should == @spec[:release]
      end

      it "parses requires from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.requires.should == @spec[:requires]
      end

      it "parses build requires from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.build_requires.should == @spec[:build_requires]
      end

      it "parses changelog from spec"

      it "parses unrpmized files from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.pkg_files.should == @spec[:files]
      end

      it "parses %check from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.has_check?.should be_true

        pspec = described_class.parse ""
        pspec.has_check?.should be_false
      end
    end
  end # describe Spec
end # module Polisher::RPM
