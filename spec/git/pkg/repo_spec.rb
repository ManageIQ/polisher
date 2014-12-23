#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/pkg'

module Polisher
  describe Git::Pkg do
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
