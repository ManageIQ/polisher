# Polisher Core Extensions Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/core'

describe String do
  describe "#gem?" do
    context "string represents path to gem" do
      it "returns true" do
        "/foo/rails.gem".should be_gem
      end
    end

    context "string does not represent path to gem" do
      it "returns false" do
        "/foo/rails.gemspec".should_not be_gem
      end
    end
  end

  describe "#gemspec?" do
    context "string represents path to gemspec" do
      it "returns true" do
        "/foo/rails.gemspec".should be_gemspec
      end
    end

    context "string does not represent path to gemspec" do
      it "returns false" do
        "/foo/rails.gem".should_not be_gemspec
      end
    end
  end

  describe "#gemfile?" do
    context "string represents path to gemfile" do
      it "returns true" do
        "/foo/Gemfile".should be_gemfile
      end
    end

    context "string does not represent path to gemfile" do
      it "returns false" do
        "/foo/foobar".should_not be_gemfile
      end
    end
  end

  describe "unrpmize" do
    it "returns string with rpm macros removed/replaced" do
      "%doc ".unrpmize.should == ""
      "%{_bindir}".unrpmize.should == "bin"
    end
  end

  describe "#rpmize" do
    it "returns string with rpm macros swapped in" do
      "bin".rpmize.should == "%{_bindir}\n%{gem_instdir}/bin"
    end

    it "prefixes %{gem_instdir} to non-special files" do
      "spec".rpmize.should == "%{gem_instdir}/spec"
      "lib".rpmize.should == "%{gem_libdir}"
      "%{gem_instdir}/foo".rpmize.should == "%{gem_instdir}/foo"
    end
  end
end # describe String
