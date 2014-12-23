#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/pkg'
require 'awesome_spawn'

module Polisher
  describe Git::Pkg do
    describe "#update_metadata" do
      it "sets pkg version" do
        pkg = described_class.new
        pkg.update_metadata(Polisher::Gem.new(:version => '5.0'))
        pkg.version.should == '5.0'
      end
    end

    describe "#update_spec_to" do
      before do
        @pkg = described_class.new
        @pkg.should_receive(:in_repo).and_yield
        @pkg.instance_variable_set(:@spec, Polisher::RPM::Spec.new)

        @gem = Polisher::Gem.new
      end

      it "updates rpm spec" do
        @pkg.spec.should_receive(:update_to).with(@gem)
        @pkg.update_spec_to(@gem)
      end

      it "writes spec to file" do
        @pkg.spec.should_receive(:update_to)
        File.should_receive(:write).with(@pkg.spec_file, @pkg.spec.to_string)
        @pkg.update_spec_to(@gem)
      end

      it "sets dirty_spec bit" do
        @pkg.spec.should_receive(:update_to)
        @pkg.update_spec_to(@gem)
        @pkg.dirty_spec.should be_true
      end
    end

    describe "#gen_sources_for" do
      it "writes gem md5sum to sources file" do
        gem = ::Polisher::Gem.new :path => 'path'
        expected = "#{described_class.md5sum_cmd} #{gem.gem_path} > sources"
        AwesomeSpawn.should_receive(:run).with(expected)

        File.should_receive(:read).with('sources').and_return('md5sum')
        File.should_receive(:write)

        pkg = described_class.new
        pkg.should_receive(:in_repo).and_yield
        pkg.gen_sources_for(gem)
      end
    end

    describe "#ignore" do
      it "adds gem to .gitignore file" do
        gem = ::Polisher::Gem.new :name => 'polisher', :version => '4.2.0'
        f = Object.new
        File.should_receive('open').with('.gitignore', 'a').and_yield(f)
        f.should_receive(:write).with("\n#{gem.name}-#{gem.version}.gem")

        pkg = described_class.new
        pkg.should_receive(:in_repo).and_yield
        pkg.ignore(gem)
      end
    end

    describe "#update_to" do
      it "updates pkg" do
        gem = Polisher::Gem.new
        pkg = described_class.new
        pkg.should_receive(:update_metadata).with(gem)
        pkg.should_receive(:update_spec_to).with(gem)
        pkg.should_receive(:gen_sources_for).with(gem)
        pkg.should_receive(:ignore).with(gem)
        pkg.update_to(gem).should == pkg
      end
    end

  end # describe Git::Pkg
end # module Polisher
