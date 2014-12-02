#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/pkg'

module Polisher
  describe Git::Pkg do
    describe "#build_srpm" do
      it "uses package command to build srpm" do
        gem  = Polisher::Gem.new(:path => "")
        spec = RPM::Spec.new
        pkg  = described_class.new
        pkg.should_receive(:in_repo).and_yield
        pkg.should_receive(:require_cmd!).with('/usr/bin/fedpkg').and_return(true)
        pkg.should_receive(:spec).and_return(spec)
        spec.should_receive(:upstream_gem).and_return(gem)
        FileUtils.stub(:ln_s) # stub out ln
        result = AwesomeSpawn::CommandResult.new "", "", "", 0
        AwesomeSpawn.should_receive(:run)
                    .with("/usr/bin/fedpkg srpm")
                    .and_return(result)
        pkg.build_srpm
      end

      context "package command fails" do
        it "raises RuntimeError with the command stderr" do
          gem  = Polisher::Gem.new(:path => "")
          spec = RPM::Spec.new
          pkg  = described_class.new
          pkg.should_receive(:in_repo).and_yield
          pkg.should_receive(:require_cmd!).with('/usr/bin/fedpkg').and_return(true)
          pkg.should_receive(:spec).and_return(spec)
          spec.should_receive(:upstream_gem).and_return(gem)
          FileUtils.stub(:ln_s) # stub out ln
          result = AwesomeSpawn::CommandResult.new "", "", "cmd_error", 1
          AwesomeSpawn.should_receive(:run)
                      .and_return(result)
          expect { pkg.build_srpm }.to raise_error(RuntimeError, "cmd_error")
        end
      end
    end

    describe "#scratch_build" do
      it "uses koji to build srpm" do
        pkg = described_class.new(:name => 'rails', :version => '1.0.0')
        pkg.should_receive(:in_repo).and_yield
        Koji.should_receive(:build).with(:srpm => pkg.srpm, :scratch => true)
        pkg.scratch_build
      end
    end

    describe "#build" do
      it "builds srpm and runs scratch build" do
        pkg = described_class.new
        pkg.should_receive(:build_srpm)
        pkg.should_receive(:scratch_build)
        pkg.build
      end
    end

  end # describe Git::Pkg
end # module Polisher
