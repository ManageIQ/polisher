# Polisher Git Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git'

module Polisher
  describe GitPackage do
    describe "#rpm_name" do
      it "returns rubygem-gem_name" do
        pkg = Polisher::GitPackage.new :name => 'rails'
        pkg.rpm_name.should == 'rubygem-rails'
      end
    end

    describe "#srpm" do
      it "returns name of srpm" do
        pkg = Polisher::GitPackage.new :name => 'rails', :version => '1.0.0'
        pkg.srpm.should == 'rubygem-rails-1.0.0-1.*.src.rpm'
      end
    end

    describe "#spec" do
      it "returns name of spec" do
        pkg = Polisher::GitPackage.new :name => 'rails'
        pkg.spec.should == 'rubygem-rails.spec'
      end
    end

    describe "::clone" do
      context "package directory does not exist" do
        it "uses package command to clone package" do
          File.should_receive(:directory?).with('rubygem-rails').and_return(false)
          AwesomeSpawn.should_receive(:run).with("/usr/bin/fedpkg clone rubygem-rails")
          Dir.should_receive(:chdir) # stub out chdir
          AwesomeSpawn.should_receive(:run).at_least(3).times
          described_class.clone "rails"
        end
      end

      it "changes dir to the pkg dir" do
        File.should_receive(:directory?).and_return(true) # stub out pull
        Dir.should_receive(:chdir).with('rubygem-rails')
        AwesomeSpawn.should_receive(:run).at_least(3).times # stub out calls to run
        described_class.clone "rails"
      end

      context "dead.package file exists" do
        it "raises Exception" do
          File.should_receive(:directory?).and_return(true) # stub out pull
          Dir.should_receive(:chdir) # stub out chdir
          File.should_receive(:exists?).with('dead.package').and_return(true)
          lambda{
            described_class.clone "rails"
          }.should raise_error(Exception)
        end
      end

      it "checks out master branch" do
        File.should_receive(:directory?).and_return(true) # stub out pull
        Dir.should_receive(:chdir).with('rubygem-rails')
        AwesomeSpawn.should_receive(:run).with("/usr/bin/git checkout master")
        AwesomeSpawn.should_receive(:run).at_least(2).times # stub out calls to run
        described_class.clone "rails"
      end

      it "resets head" do
        File.should_receive(:directory?).and_return(true) # stub out pull
        Dir.should_receive(:chdir).with('rubygem-rails')
        AwesomeSpawn.should_receive(:run).with("/usr/bin/git reset HEAD~ --hard")
        AwesomeSpawn.should_receive(:run).at_least(2).times # stub out calls to run
        described_class.clone "rails"
      end

      it "pulls from remote" do
        File.should_receive(:directory?).and_return(true) # stub out pull
        Dir.should_receive(:chdir).with('rubygem-rails')
        AwesomeSpawn.should_receive(:run).with("/usr/bin/git pull")
        AwesomeSpawn.should_receive(:run).at_least(2).times # stub out calls to run
        described_class.clone "rails"
      end

      it "returns new GitPackage instance" do
        File.should_receive(:directory?).and_return(true) # stub out pull
        Dir.should_receive(:chdir).with('rubygem-rails')
        AwesomeSpawn.should_receive(:run).at_least(3).times # stub out calls to run
        pkg = described_class.clone("rails")
        pkg.should be_an_instance_of(described_class)
        pkg.name.should == 'rails'
      end
    end

    describe "#update_to" do
      it "updates rpm spec"
      it "updates sources file"
      it "updates .gitignore file"
    end

    describe "#build" do
      it "uses package command to build srpm" do
        AwesomeSpawn.should_receive(:run).with("/usr/bin/fedpkg srpm")
        AwesomeSpawn.should_receive(:run).at_least(:once)
        described_class.new.build
      end

      it "uses build command to build srpm" do
        AwesomeSpawn.should_receive(:run).with("/usr/bin/koji build --scratch rawhide rubygem-rails-1.0.0-1.*.src.rpm")
        AwesomeSpawn.should_receive(:run).at_least(:once)
        described_class.new(:name => 'rails', :version => '1.0.0').build
      end
    end

    describe "#has_check?" do
      context "package spec has %check section" do
        it "returns true" do
          File.should_receive(:open).with("rubygem-rails.spec", "r").and_yield("%check")
          described_class.new(:name => "rails").has_check?.should be_true
        end
      end

      context "package spec does not have a %check section" do
        it "returns false" do
          File.should_receive(:open).with("rubygem-rails.spec", "r").and_yield("")
          described_class.new(:name => "rails").has_check?.should be_false
        end
      end
    end

    describe "#commit" do
      it "git adds the sources, .gitignore, and spec files" do
        AwesomeSpawn.should_receive(:run).with("/usr/bin/git add rubygem-rails.spec sources .gitignore")
        AwesomeSpawn.should_receive(:run).at_least(:once)
        described_class.new(:name => 'rails').commit
      end

      it "commits the package" do
        AwesomeSpawn.should_receive(:run).with("/usr/bin/git commit -m 'updated to 1.0.0'")
        AwesomeSpawn.should_receive(:run).at_least(:once)
        described_class.new(:name => 'rails', :version => '1.0.0').commit
      end
    end

    describe "#version_for" do
      it "uses git to retrieve the package" do
        AwesomeSpawn.should_receive(:run).with("/usr/bin/git clone #{described_class::DIST_GIT_URL}rubygem-rails.git .")
        described_class.version_for 'rails'
      end

      it "parses version from spec in git" do
        AwesomeSpawn.should_receive(:run) # stub out run
        File.should_receive(:read).with("rubygem-rails.spec").and_return("contents")
        Polisher::RPMSpec.should_receive(:parse).with("contents").and_return(Polisher::RPMSpec.new)
        described_class.version_for 'rails'
      end

      it "returns version of the package" do
        spec = Polisher::RPMSpec.new :version => '1.0.0'
        AwesomeSpawn.should_receive(:run) # stub out run
        File.should_receive(:read).with("rubygem-rails.spec") # stub out read
        Polisher::RPMSpec.should_receive(:parse).and_return(spec)
        described_class.version_for('rails').should == '1.0.0'
      end

      it "invokes callback with version of package" do
        spec = Polisher::RPMSpec.new :version => '1.0.0'
        AwesomeSpawn.should_receive(:run) # stub out run
        File.should_receive(:read).with("rubygem-rails.spec") # stub out read
        Polisher::RPMSpec.should_receive(:parse).and_return(spec)

        cb = proc {}
        cb.should_receive(:call).with(:git, 'rails', ['1.0.0'])
        described_class.version_for('rails', &cb)
      end
    end

  end # describe GitPackage
end # module Polisher
