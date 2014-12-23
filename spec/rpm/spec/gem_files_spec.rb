#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "::file_satisfies?" do
      context "spec file is same as gemfile" do
        it "returns true" do
          described_class.file_satisfies?('file1', 'file1').should be_true
        end
      end

      context "spec file is dir containing gemfile" do
        it "returns true" do
          described_class.file_satisfies?('dir', 'dir/file1').should be_true
        end
      end

      context "spec file and gem file are not related" do
        it "returns false" do
          described_class.file_satisfies?('foo', 'bar').should be_false
        end
      end
    end

    describe "#missing_gem_file?" do
      context "no spec files satisfies specified gem file" do
        it "returns true" do
          spec = described_class.new
          spec.should_receive(:files).and_return(['file1'])
          described_class.should_receive(:file_satisfies?)
                         .with('file1', 'gem_file')
                         .and_return(false)
          spec.missing_gem_file?('gem_file').should be_true
        end
      end

      context "at least one spec file satisfying specified gem file" do
        it "returns false" do
          spec = described_class.new
          spec.should_receive(:files).and_return(%w(file1 file2))
          described_class.should_receive(:file_satisfies?)
                         .with('file1', 'gem_file')
                         .and_return(false)
          described_class.should_receive(:file_satisfies?)
                         .with('file2', 'gem_file')
                         .and_return(true)
          spec.missing_gem_file?('gem_file').should be_false
        end
      end
    end

    describe "#missing_files_for" do
      it "returns gem files for which there are no satisfying spec files" do
        gem = Polisher::Gem.new
        gem.should_receive(:file_paths).and_return(%w(file1 file2))

        spec = described_class.new
        spec.should_receive(:missing_gem_file?)
            .with('file1').and_return(false)
        spec.should_receive(:missing_gem_file?)
            .with('file2').and_return(true)
        spec.missing_files_for(gem).should == ['file2']
      end
    end

    describe "#excluded files" do
      it "returns files excluded from upstream gem" do
        gem = Polisher::Gem.new
        spec = described_class.new
        spec.should_receive(:upstream_gem).and_return(gem)
        spec.should_receive(:missing_files_for)
            .with(gem).and_return(['file1'])
        spec.excluded_files.should == ['file1']
      end
    end

    describe "#excludes_file?" do
      context "file on excluded files list" do
        it "returns true" do
          spec = described_class.new
          spec.should_receive(:excluded_files).and_return(%w(file1 file2))
          spec.excludes_file?('file1').should be_true
        end
      end

      context "file not on excluded files list" do
        it "returns false" do
          spec = described_class.new
          spec.should_receive(:excluded_files).and_return(%w(file1 file2))
          spec.excludes_file?('foobar').should be_false
        end
      end
    end

  end # describe Spec
end # module Polisher::RPM
