#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'awesome_spawn'
require 'polisher/git/repo'

module Polisher
  describe Git::Repo do
    describe "#initialize" do
      it "initializes url" do
        repo = described_class.new :url => 'repo_url'
        repo.url.should == 'repo_url'
      end
    end

    describe "#path" do
      it "returns set path" do
        repo = described_class.new :path => 'repo_path'
        repo.path.should == 'repo_path'
      end

      it "returns git cache path for url" do
        repo = described_class.new :url => 'repo_url'
        Polisher::GitCache.should_receive(:path_for)
                          .with('repo_url')
                          .and_return('repo_path')
        repo.path.should == 'repo_path'
      end
    end

    describe "#clobber" do
      it "rm -rf's path" do
        repo = described_class.new :path => 'repo_path'
        FileUtils.should_receive(:rm_rf).with('repo_path')
        repo.clobber!
        RSpec::Mocks.proxy_for(FileUtils).reset # XXX
      end
    end

    describe "#clone" do
      it "runs git clone" do
        expected = "/usr/bin/git clone repo_url repo_path"
        AwesomeSpawn.should_receive(:run!).with(expected)

        repo = described_class.new :url => 'repo_url'
        repo.should_receive(:path).and_return('repo_path')
        repo.clone
      end
    end

    describe "#cloned?" do
      before(:each) do
        @repo = described_class.new
        @repo.should_receive(:path).and_return('repo_path')
      end

      context "repo path directory exists" do
        it "returns true" do
          File.should_receive(:directory?).with('repo_path').and_return(true)
          @repo.should be_cloned
        end
      end

      context "repo path directory does not exist" do
        it "returns false" do
          File.should_receive(:directory?).with('repo_path').and_return(false)
          @repo.should_not be_cloned
        end
      end
    end

    describe "#in_repo" do
      it "chdir to repo path, invokes block, restores dir" do
        repo = described_class.new
        Dir.mktmpdir do |dir|
          repo.should_receive(:path).and_return(dir)

          expected = Pathname.new(dir).realpath.to_s
          invoked = false
          orig = Dir.pwd
          repo.in_repo do
            Dir.pwd.should == expected
            invoked = true
          end
          Dir.pwd.should == orig
          invoked.should be_true
        end
      end
    end

    describe "#file_paths" do
      it "returns list of all first paths in git repo" do
        expected = ['file1', 'dir1/file2', 'dir2']
        repo = described_class.new
        repo.should_receive(:in_repo).and_yield
        Dir.should_receive(:[]).with('**/*').and_return(expected)
        repo.file_paths.should == expected
      end
    end

    describe "#include?" do
      context "file paths includes file" do
        it "returns true" do
          repo = described_class.new
          repo.should_receive(:file_paths).and_return(['foo'])
          repo.include?('foo').should be_true
        end
      end

      context "file paths does not include file" do
        it "returns false" do
          repo = described_class.new
          repo.should_receive(:file_paths).and_return([])
          repo.include?('foo').should be_false
        end
      end
    end

    describe "#reset!" do
      it "resets git repo to head" do
        expected = "/usr/bin/git reset HEAD~ --hard"
        repo = described_class.new
        repo.should_receive(:in_repo).and_yield
        AwesomeSpawn.should_receive(:run!).with(expected)
        repo.reset!
      end
    end

    describe "#pull" do
      it "git pulls" do
        expected = "/usr/bin/git pull"
        repo = described_class.new
        repo.should_receive(:in_repo).and_yield
        AwesomeSpawn.should_receive(:run!).with(expected)
        repo.pull
      end
    end

    describe "#checkout" do
      it "git checks out target" do
        expected = "/usr/bin/git checkout master"
        repo = described_class.new
        repo.should_receive(:in_repo).and_yield
        AwesomeSpawn.should_receive(:run!).with(expected)
        repo.checkout('master')
      end
    end

    describe "#commit" do
      it "git commits with message" do
        expected = "/usr/bin/git commit -m 'msg'"
        repo = described_class.new
        repo.should_receive(:in_repo).and_yield
        AwesomeSpawn.should_receive(:run!).with(expected)
        repo.commit('msg')
      end
    end
  end
end # module Polisher
