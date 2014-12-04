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

    describe "#spec?" do
      context "repo includes spec file" do
        it "returns true" do
          pkg = described_class.new :name => 'rails'
          pkg.should_receive(:include?).with(pkg.spec_file).and_return(true)
          pkg.spec?.should be_true
        end
      end

      context "repo does not include spec file" do
        it "returns false" do
          pkg = described_class.new :name => 'rails'
          pkg.should_receive(:include?).with(pkg.spec_file).and_return(false)
          pkg.spec?.should be_false
        end
      end
    end

    describe "#spec" do
      before do
        @pkg = described_class.new :name => 'rails'
        @pkg.should_receive(:in_repo)
            .at_least(:once)
            .and_yield
        File.should_receive(:read)
            .with(@pkg.spec_file)
            .at_least(:once)
            .and_return("spec")
      end

      it "returns handle to parsed Polisher::RPM::Spec" do
        spec = Polisher::RPM::Spec.new
        Polisher::RPM::Spec.should_receive(:parse)
                           .with('spec')
                           .once
                           .and_return(spec)
        @pkg.spec.should == spec
        @pkg.spec.should == spec
      end

      context "dirty_spec bit is set true" do
        it "reparses spec" do
          spec = Polisher::RPM::Spec.new
          Polisher::RPM::Spec.should_receive(:parse)
                             .with('spec')
                             .twice
                             .and_return(spec)
          @pkg.spec.should == spec
          @pkg.dirty_spec = true
          @pkg.spec.should == spec
        end

        it "resets dirty_spec bit" do
          spec = Polisher::RPM::Spec.new
          Polisher::RPM::Spec.should_receive(:parse).and_return(spec)
          @pkg.dirty_spec = true
          @pkg.spec
          @pkg.dirty_spec.should be_false
        end
      end
    end

    describe "#pkg_files" do
      it "returns spec, .gitignore, sources" do
        pkg = described_class.new :name => 'thor'
        pkg.pkg_files.should == [pkg.spec_file, 'sources', '.gitignore']
      end
    end

    describe "#path" do
      it "returns Git Cache path for rpm name" do
        pkg = described_class.new :name => 'thor'
        GitCache.should_receive(:path_for).with(pkg.rpm_name).and_return "path"
        pkg.path.should == "path"
      end
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
