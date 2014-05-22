#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git'
require 'pathname'

module Polisher
  describe Git::Repo do
    describe "#initialize" do
      it "initializes url" do
        repo = described_class.new :url => 'repo_url'
        repo.url.should == 'repo_url'
      end
    end

    describe "#path" do
      it "returns git cache path for url" do
        repo = described_class.new :url => 'repo_url'
        Polisher::GitCache.should_receive(:path_for).
                                    with('repo_url').
                             and_return('repo_path')
        repo.path.should == 'repo_path'
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

  describe Git::Pkg do
    describe "#initialize" do
      it "initializes name" do
        pkg = described_class.new :name => 'pkg_name'
        pkg.name.should == 'pkg_name'
      end

      it "initializes version" do
        pkg = described_class.new :version => 'pkg_version'
        pkg.version.should == 'pkg_version'
      end
    end

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
          File.should_receive(:exists?).with('dead.package').and_return(true)
          @pkg.should be_dead
        end
      end

      context "dead.package does not exist" do
        it "returns false" do
          File.should_receive(:exists?).with('dead.package').and_return(false)
          @pkg.should_not be_dead
        end
      end
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
          lambda{
            @pkg.fetch
          }.should raise_error(Exception)
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

    describe "#update_spec_to" do
      it "updates spec version"
      it "updates spec release"
    end

    describe "#gen_sources_for" do
      it "writes gem md5sum to sources file"
    end

    describe "#ignore" do
      it "adds gem to .gitignore file"
    end

    describe "#update_to" do
      it "updates rpm spec"
      it "generates new sources file"
      it "ignores gem"
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

    describe "#build_srpm" do
      it "uses package command to build srpm" do
        pkg = described_class.new
        pkg.should_receive(:in_repo).and_yield
        AwesomeSpawn.should_receive(:run).with("/usr/bin/fedpkg srpm")
        pkg.build_srpm
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

    describe "#versions_for" do
      it "git fetches the package" do
        pkg = described_class.new
        described_class.should_receive(:new)
                       .with(:name => 'rails')
                       .and_return(pkg)
        pkg.should_receive(:fetch).with(described_class.fetch_tgt)
        described_class.versions_for 'rails'
      end

      it "returns version of the package" do
        spec = Polisher::RPM::Spec.new :version => '1.0.0'
        pkg  = described_class.new
        pkg.should_receive(:fetch) # stub out fetch
        described_class.should_receive(:new).and_return(pkg)
        pkg.should_receive(:spec).and_return(spec)

        described_class.versions_for('rails').should == ['1.0.0']
      end

      it "invokes callback with version of package" do
        spec = Polisher::RPM::Spec.new :version => '1.0.0'
        pkg  = described_class.new
        pkg.should_receive(:fetch) # stub out fetch
        described_class.should_receive(:new).and_return(pkg)
        pkg.should_receive(:spec).and_return(spec)

        cb = proc {}
        cb.should_receive(:call).with(:git, 'rails', ['1.0.0'])
        described_class.versions_for('rails', &cb)
      end
    end
  end # describe Git::Pkg

  describe Git::Project do
    describe "#vendored" do
      context "repo not cloned" do
        it "clones repo" do
          git = described_class.new
          git.should_receive(:cloned?).and_return(false)
          git.should_receive(:clone)
          git.should_receive(:vendored_file_paths).and_return([]) # stub out
          git.vendored
        end
      end
    end
  end
end # module Polisher
