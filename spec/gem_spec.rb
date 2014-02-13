# Polisher Gem Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'spec_helper'

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "#initialize" do
      it "sets gem attributes" do
        gem = Polisher::Gem.new :name => 'rails',
                                :version => '4.0.0',
                                :deps => ['activesupport', 'activerecord'],
                                :dev_deps => ['rake']
        gem.name.should == 'rails'
        gem.version.should == '4.0.0'
        gem.deps.should == ['activesupport', 'activerecord']
        gem.dev_deps.should == ['rake']
      end
    end

    describe "#ignorable_file?" do
      context "args matches an ignorable file" do
        it "returns true" do
          Polisher::Gem.ignorable_file?('foo.gemspec').should be_true
          Polisher::Gem.ignorable_file?('Gemfile').should be_true
        end
      end

      context "args does not match an ignorable file" do
        it "returns false" do
          Polisher::Gem.ignorable_file?('.rvmra').should be_false
          Polisher::Gem.ignorable_file?('foo.gemspoc').should be_false
        end
      end
    end

    describe "#local_versions_for" do
      it "returns versions of specified gem in local db"
      it "invokes cb with versions retrieved"
    end

    describe "#parse" do
      it "returns new gem" do
        gem = Polisher::Gem.parse
        gem.should be_an_instance_of(Polisher::Gem)
      end

      it "parses gem from gem spec" do
        spec = Polisher::Test::GEM_SPEC
        gem  = Polisher::Gem.parse(:gemspec => spec[:path])
        gem.name.should     == spec[:name]
        gem.version.should  == spec[:version]
        gem.deps.should     == spec[:deps]
        gem.dev_deps.should == spec[:dev_deps]
      end

      it "parses gem from gem at path"

      it "parses gem from metadata hash" do
        gemj = Polisher::Test::GEM_JSON
        gem = Polisher::Gem.parse gemj[:json]
        gem.name.should     == gemj[:name]
        gem.version.should  == gemj[:version]
        gem.deps.should     == gemj[:deps]
        gem.dev_deps.should == gemj[:dev_deps]
      end
    end


    describe "#download_gem" do
      context "gem in GemCache" do
        it "returns GemCache gem"
      end

      it "uses curl to download gem"
      it "sets gem in gem cached"
      it "returns downloaded gem binary contents"
    end

    describe "#download_gem_path" do
      it "downloads gem" do
        gem = Polisher::Gem.new
        gem.should_receive(:download_gem)
        gem.downloaded_gem_path
      end

      it "returns gem cache path for gem" do
        # stub out d/l
        gem = Polisher::Gem.new :name => 'rails', :version => '1.0'
        gem.should_receive(:download_gem)
        Polisher::GemCache.should_receive(:path_for).
                           with('rails', '1.0').
                           at_least(:once).
                           and_return('rails_path')
        gem.downloaded_gem_path.should == 'rails_path'
      end
    end

    describe "#gem_path" do
      it "returns specified path" do
        gem = Polisher::Gem.new :path => 'gem_path'
        gem.gem_path.should == 'gem_path'
      end

      context "specified path is null" do
        it "returns downloaded gem path" do
          gem = Polisher::Gem.new
          gem.should_receive(:downloaded_gem_path).and_return('gem_path')
          gem.gem_path.should == 'gem_path'
        end
      end
    end

    describe "#unpack" do
      it "unpacks gem at gem_path into temp dir"
      it "returns tmp dir"
      context "block specified" do
        it "invokes block with tmp dir"
        it "removes tmp dir"
        it "returns nil"
      end
    end

    describe "#file_paths" do
      it "returns list of file paths in gem"
    end

    describe "#retrieve" do
      before(:each) do
        @local_gem = Polisher::Test::LOCAL_GEM
      end

      it "returns gem retrieved from rubygems" do
        gem = Polisher::Gem.retrieve(@local_gem[:name])
        gem.should be_an_instance_of(Polisher::Gem)
        gem.name.should     == @local_gem[:name]
        gem.version.should  == @local_gem[:version]
        gem.deps.should     == @local_gem[:deps]
        gem.dev_deps.should == @local_gem[:dev_deps]
      end
    end

    describe "#versions" do
      it "looks up and returns versions for gemname in polisher version checker"

      context "recursive is true" do
        it "appends versions of gem dependencies to versions list"
        context "dev_deps is true" do
          it "appends versions of gem dev dependencies to versions list"
        end
      end
    end

    describe "#diff" do
      before(:each) do
        @gem1 = Polisher::Gem.new
        @gem2 = Polisher::Gem.new

        @result = AwesomeSpawn::CommandResult.new '', 'diff_out', '', 0
      end

      it "runs diff against unpacked local and other gems and returns output" do
        @gem1.should_receive(:unpack).and_return('dir1')
        @gem2.should_receive(:unpack).and_return('dir2')
        AwesomeSpawn.should_receive(:run).
          with("#{Polisher::Gem::DIFF_CMD} -r dir1 dir2").
          and_return(@result)
        @gem1.diff(@gem2).should == @result.output
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
