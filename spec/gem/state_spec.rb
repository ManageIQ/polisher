#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "#koji_tags" do
      it "returns hash of configured koji tags to versions of gem in them"
    end

    describe "#koji_state" do
      context "koji_tags are empty" do
        it "returns :missing"
      end

      context "no dependency check specified" do
        it "returns :available"
      end

      context "version in koji tag matches dependency check" do
        it "returns available"
      end

      context "dependency check is not satisfied" do
        it "returns missing"
      end
    end

    describe "#distgit" do
      it "return distgit package for gem"
    end

    describe "#distgit_branches" do
      it "maps koji tags to distgit branches and returns"

      context "koji tags are empty" do
        it "returns valid distgit branches"
      end

      context "no corresponding distgit branches to koji tags" do
        it "returns valid distgit branches"
      end
    end

    describe "#distgit_versions" do
      it "returns versions of specs in distgit branches"
    end

    describe "#distgit_state" do
      it "clones distgit repo"

      context "error cloning repo" do
        it "returns :missing_repo"
      end

      context "valid_branches are empty" do
        it "returns :missing_branch"
      end

      context "distgit_versions are empty" do
        it "returns :missing_spec"
      end

      context "dependency check not specified" do
        it "returns :available"
      end

      context "version in distgit matches dependency check" do
        it "returns :available"
      end

      context "dependency check not satisfieid" do
        it "returns :missing"
      end
    end
  end # describe Gem
end # module Polisher
