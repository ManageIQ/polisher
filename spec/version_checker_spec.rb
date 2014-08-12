# Polisher Version Checker Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/version_checker'

module Polisher
  describe VersionChecker do
    describe "#check" do
      it "adds target to check to list"
    end

    describe "#should_check?" do
      context "target is on check list" do
        it "returns true"
      end

      context "target is not on check list" do
        it "returns false"
      end
    end

    describe "#versions_for" do
      context "should check gem target" do
        it "checks gem target"
        it "invokes block w/ gem versions retrieved"
      end

      context "should check fedora target" do
        it "checks fedora target"
        it "invokes block w/ fedora versions retrieved"
        context "error retrieving versions from fedora" do
          it "invokes block w/ 'unknown' version"
          it "returns 'unknown' fedora version"
        end
      end

      context "should check koji target" do
        it "checks koji target"
        it "invokes block w/ koji versions retrieved"
        context "error retrieving versions from koji" do
          it "invokes block w/ 'unknown' version"
          it "returns 'unknown' koji version"
        end
      end

      context "should check git target" do
        it "checks git target"
        it "invokes block w/ git versions retrieved"
        context "error retrieving versions from git" do
          it "invokes block w/ 'unknown' version"
          it "returns 'unknown' git version"
        end
      end

      context "should check yum target" do
        it "checks yum target"
        it "invokes block w/ yum versions retrieved"
        context "error retrieving versions from yum" do
          it "invokes block w/ 'unknown' version"
          it "returns 'unknown' yum version"
        end
      end

      context "should check bodhi target" do
        it "checks bodhi target"
        it "invokes block w/ bodhi versions retrieved"
        context "error retrieving versions from bodhi" do
          it "invokes block w/ 'unknown' version"
          it "returns 'unknown' bodhi version"
        end
      end

      context "should check errata target" do
        it "checks errata target"
        it "checks errata target"
        it "invokes block w/ errata versions retrieved"
        context "error retrieving versions from errata" do
          it "invokes block w/ 'unknown' version"
          it "returns 'unknown' errata version"
        end
      end

      it "returns all versions retrieved"
    end

    describe "#version_for" do
      it "retrieves most relevant version of package in configured targets" do
        versions = {:koji => ['1.0', '1.0', '2.0'],
                    :git  => ['1.0', '2.1', '2.1'],
                    :yum  => ['0.9', '0.9', '0.9']}
        described_class.should_receive(:versions_for).and_return(versions)

        expected = {:koji => '1.0',
                    :git  => '2.1',
                    :yum  => '0.9'}
        described_class.version_for('rails').should == expected
      end
    end

    describe "#version_of" do
      it "retrieves most relevant version of package in all targets" do
        versions = {:koji   => '2.2',
                    :bodhi  => '1.1',
                    :errata => '1.1'}
        described_class.should_receive(:version_for).and_return(versions)
        described_class.version_of('rails').should == '1.1'
      end
    end
  end # describe VersionChecker
end # module Polisher
