#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/git/repo'
require 'awesome_spawn'

module Polisher
  describe Gem do
    describe "#diff" do
      before(:each) do
        @gem1 = described_class.new
        @gem2 = described_class.new
        @repo = Polisher::Git::Repo.new
        @result = AwesomeSpawn::CommandResult.new '', 'diff_out', '', 0
      end

      it "requires awesome_spawn dependency" do
        @gem1.should_receive(:require_dep!).with('awesome_spawn')
        @gem1.diff(@gem2)
      end

      it "requires diff cmd" do
        @gem1.should_receive(:require_cmd!).with(@gem1.diff_cmd)
        @gem1.diff(@gem2)
      end

      it "runs diff against unpacked local and other gems and returns output" do
        @gem1.should_receive(:unpack).and_return('dir1')
        @gem2.should_receive(:unpack).and_return('dir2')
        AwesomeSpawn.should_receive(:run)
          .with("#{Polisher::Gem.diff_cmd} -r dir1 dir2")
          .and_return(@result)
        @gem1.diff(@gem2).should == @result.output
      end

      it "runs diff against unpacked local gem and git repo and returns output" do
        @gem1.should_receive(:unpack).and_return('dir1')
        @repo.should_receive(:path).and_return('dir2')
        AwesomeSpawn.should_receive(:run)
          .with("#{Polisher::Gem.diff_cmd} -r dir1 dir2")
          .and_return(@result)
        @gem1.diff(@repo).should == @result.output
      end

      it "replaces directories in output" do
        @gem1.should_receive(:unpack).and_return('dir1')
        @gem2.should_receive(:unpack).and_return('dir2')
        @result = AwesomeSpawn::CommandResult.new '', 'dir1Adir2B', '', 0
        AwesomeSpawn.should_receive(:run).and_return(@result)
        @gem1.diff(@gem2).should == 'aAbB'
      end

      it "removes unpacked gem dirs" do
        @gem1.should_receive(:unpack).and_return('dir1')
        @gem2.should_receive(:unpack).and_return('dir2')
        AwesomeSpawn.should_receive(:run).and_return(@result)
        FileUtils.should_receive(:rm_rf).with('dir1')
        FileUtils.should_receive(:rm_rf).with('dir2')
        # XXX for the GemCache dir cleaning:
        FileUtils.should_receive(:rm_rf).at_least(:once)
        @gem1.diff(@gem2)
      end

      context "error during operations" do
        it "removes unpacked gem dirs" do
          @gem1.should_receive(:unpack).and_return('dir1')
          @gem2.should_receive(:unpack).and_return('dir2')
          AwesomeSpawn.should_receive(:run).
            and_raise(AwesomeSpawn::CommandResultError.new('', ''))
          FileUtils.should_receive(:rm_rf).with('dir1')
          FileUtils.should_receive(:rm_rf).with('dir2')
          FileUtils.should_receive(:rm_rf).at_least(:once)
          @gem1.diff(@gem2)
        end
      end
    end
  end # describe Gem
end # module Polisher
