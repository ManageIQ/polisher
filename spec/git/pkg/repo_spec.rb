#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/pkg'
require 'awesome_spawn'

module Polisher
  describe Git::Pkg do
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


    describe "#fetch" do
      before(:each) do
        @pkg = described_class.new
      end

      context "pkg not cloned" do
        it "clones package" do
          @pkg.should_receive(:dead?).and_return(false)
          @pkg.should_receive(:reset!)
          @pkg.should_receive(:checkout)
          @pkg.should_receive(:pull)

          @pkg.should_receive(:cloned?).and_return(false)
          @pkg.should_receive(:clone)
          @pkg.fetch
        end
      end

      context "pkg cloned" do
        it "does not clone pkg" do
          @pkg.should_receive(:dead?).and_return(false)
          @pkg.should_receive(:reset!)
          @pkg.should_receive(:checkout)
          @pkg.should_receive(:pull)

          @pkg.should_receive(:cloned?).and_return(true)
          @pkg.should_not_receive(:clone)
          @pkg.fetch
        end
      end

      context "pkg dead" do
        it "raises Exception" do
          @pkg.should_receive(:cloned?).and_return(true)
          @pkg.should_receive(:dead?).and_return(true)
          lambda{ @pkg.fetch }.should raise_error(Exception)
        end
      end

      it "checks out master" do
        @pkg.should_receive(:cloned?).and_return(true)
        @pkg.should_receive(:dead?).and_return(false)
        @pkg.should_receive(:reset!)
        @pkg.should_receive(:pull)

        @pkg.should_receive(:checkout).with('master')
        @pkg.fetch
      end

      it "resets HEAD" do
        @pkg.should_receive(:cloned?).and_return(true)
        @pkg.should_receive(:dead?).and_return(false)
        @pkg.should_receive(:checkout)
        @pkg.should_receive(:pull)

        @pkg.should_receive(:reset!)
        @pkg.fetch
      end

      it "pulls repo" do
        @pkg.should_receive(:cloned?).and_return(true)
        @pkg.should_receive(:dead?).and_return(false)
        @pkg.should_receive(:reset!)
        @pkg.should_receive(:checkout)

        @pkg.should_receive(:pull)
        @pkg.fetch
      end
    end

    describe "#valid_targets" do
      before do
        @fetch_tgts = described_class.fetch_tgts
        described_class.fetch_tgt ['t1', 't2']
      end

      after do
        described_class.fetch_tgt @fetch_tgts
      end

      it "returns fetchable targets" do
        pkg = described_class.new
        pkg.should_receive(:fetch).with('t1')
        pkg.should_receive(:fetch).with('t2').and_raise(RuntimeError)
        pkg.valid_targets.should == ['t1']
      end
    end

    describe "#commit" do
      it "git adds the pkg_files" do
        pkg = described_class.new(:name => 'rails')
        pkg.should_receive(:in_repo).at_least(:once).and_yield
        pkg.should_receive(:pkg_files).and_return(['pkg_files'])
        expected = "/usr/bin/git add pkg_files"
        AwesomeSpawn.should_receive(:run).with(expected)
        AwesomeSpawn.should_receive(:run).at_least(:once)
                    .and_return(AwesomeSpawn::CommandResult.new('', '', '', 0))
        pkg.commit
      end

      it "commits the package with default msg" do
        pkg = described_class.new(:name => 'rails', :version => '1.0.0')
        pkg.should_receive(:in_repo).at_least(:once).and_yield
        expected = "/usr/bin/git commit -m 'updated to 1.0.0'"
        AwesomeSpawn.should_receive(:run!).with(expected)
        AwesomeSpawn.should_receive(:run).at_least(:once)
                    .and_return(AwesomeSpawn::CommandResult.new('', '', '', 0))
        pkg.commit
      end
    end
  end # describe Git::Pkg
end # module Polisher
