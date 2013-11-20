# Polisher Git Spec
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'polisher/git'

module Polisher
  describe GitPackage do
    describe "#rpm_name" do
      it "returns rubygem-gem_name" do
        pkg = Polisher::GitPackage.new :name => 'rails'
        pkg.rpm_name.should == 'rubygem-rails'
      end
    end

    describe "#srpm" do
      it "returns name of srpm" do
        pkg = Polisher::GitPackage.new :name => 'rails', :version => '1.0.0'
        pkg.srpm.should == 'rubygem-rails-1.0.0-1.*.src.rpm'
      end
    end

    describe "#spec" do
      it "returns name of spec" do
        pkg = Polisher::GitPackage.new :name => 'rails'
        pkg.spec.should == 'rubygem-rails.spec'
      end
    end

    describe "#clone" do
      context "package directory does not exist" do
        it "uses package command to clone package"
      end

      context "dead.package file exists" do
        it "raises Exception"
      end

      it "checks out master branch"
      it "resets head"
      it "pulls from remote"

      it "returns new GitPackage instance"
    end

    describe "#update_to" do
      it "updates rpm spec"
      it "updates sources file"
      it "updates .gitignore file"
    end

    describe "#build" do
      it "uses package command to build srpm"
      it "uses build command to build srpm"
    end

    describe "#has_check?" do
      context "package spec has %check section" do
        it "returns true"
      end

      context "package spec does not have a %check section" do
        it "returns false"
      end
    end

    describe "#commit" do
      it "git adds the sources, .gitignore, and spec files"
      it "commits the package"
    end

  end # describe GitPackage
end # module Polisher
