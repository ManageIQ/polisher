#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/pkg'

module Polisher
  describe Git::Pkg do
    describe "#rpm_name" do
      it "returns rubygem-gem_name" do
        pkg = described_class.new :name => 'rails'
        pkg.rpm_name.should == 'rubygem-rails'
      end
    end

    describe "#srpm" do
      it "returns name of srpm" do
        pkg = described_class.new :name => 'rails', :version => '1.0.0'
        pkg.srpm.should == 'rubygem-rails-1.0.0-1.*.src.rpm'
      end
    end

    describe "#spec_file" do
      it "returns name of spec file" do
        pkg = described_class.new :name => 'rails'
        pkg.spec_file.should == 'rubygem-rails.spec'
      end
    end

    describe "#spec" do
      it "returns handle to parsed Polisher::RPM::Spec"
    end

    describe "#pkg_files" do
      it "returns spec, .gitignore, sources"
    end

    describe "#path" do
      it "returns Git Cache path for rpm name"
    end

    describe "#git_clone" do
      it "is an alias for superclass#clone"
    end

    describe "#clone" do
      it "clones package" do
        # stub out glob / rm_rf
        Dir.should_receive(:foreach).and_return([])
        FileUtils.should_receive(:rm_rf).at_least(:once)

        pkg = described_class.new :name => 'rails'
        pkg.should_receive(:in_repo).and_yield
        pkg.should_receive(:require_cmd!).with('/usr/bin/fedpkg').and_return(true)

        expected = '/usr/bin/fedpkg clone rubygem-rails'
        result   = AwesomeSpawn::CommandResult.new '', '', '', 0
        AwesomeSpawn.should_receive(:run).with(expected).and_return(result)
        pkg.clone
      end

      it "moves files from pkg subdir to current dir"
      it "rm's pkg subdir"
    end

    describe "#dead?" do
      before(:each) do
        @pkg = described_class.new
        @pkg.should_receive(:in_repo).and_yield
      end

      context "dead.package exists" do
        it "returns true" do
          File.should_receive(:exist?).with('dead.package').and_return(true)
          @pkg.should be_dead
        end
      end

      context "dead.package does not exist" do
        it "returns false" do
          File.should_receive(:exist?).with('dead.package').and_return(false)
          @pkg.should_not be_dead
        end
      end
    end
  end # describe Git::Pkg
end # module Polisher
