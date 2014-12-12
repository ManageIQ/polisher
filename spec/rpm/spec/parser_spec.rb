#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "#parse" do
      it "returns new rpmspec instance" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.should be_an_instance_of(described_class)
      end

      it "parses contents from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.contents.should == rpm_spec[:contents]
      end

      it "parses name from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.gem_name.should == rpm_spec[:name]
      end

      it "parses version from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.version.should == rpm_spec[:version]
      end

      it "parses release from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.release.should == rpm_spec[:release]
      end

      it "parses requires from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.requires.should == rpm_spec[:requires]
      end

      it "parses build requires from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.build_requires.should == rpm_spec[:build_requires]
      end

      it "parses changelog from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.changelog.should == rpm_spec.changelog
      end

      it "parses unrpmized files from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.pkg_files.should == rpm_spec[:files]
      end

      it "parses %check from spec" do
        pspec = described_class.parse rpm_spec[:contents]
        pspec.has_check?.should be_true

        pspec = described_class.parse ""
        pspec.has_check?.should be_false
      end
    end
  end # describe Spec
end # module Polisher::RPM
