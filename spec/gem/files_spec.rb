#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "#ignorable_file?" do
      context "args matches an ignorable file" do
        it "returns true" do
          described_class.ignorable_file?('foo.gemspec').should be_true
          described_class.ignorable_file?('Gemfile').should be_true
        end
      end

      context "args does not match an ignorable file" do
        it "returns false" do
          described_class.ignorable_file?('.rvmra').should be_false
          described_class.ignorable_file?('foo.gemspoc').should be_false
        end
      end
    end

    describe "#doc_file?" do
      context "file is on doc file list" do
        it "returns true" do
          described_class.doc_file?('CHANGELOG').should be_true
        end
      end

      context "file is not on doc file list" do
        it "returns false" do
          described_class.doc_file?('foobar.rb').should be_false
        end
      end
    end

    describe "#has_file_satisfied_by?" do
      context "specified spec file satisfies at least one gem file" do
        it "returns true" do
          spec_file = 'spec_file'
          gem_file  = 'gem_file'
          RPM::Spec.should_receive(:file_satisfies?)
                   .with(spec_file, gem_file)
                   .and_return(true)

          gem = Polisher::Gem.new
          gem.should_receive(:file_paths).and_return([gem_file])
          gem.has_file_satisfied_by?(spec_file).should be_true
        end
      end

      context "specified spec file does not satisfy any gem files" do
        it "returns false" do
          spec_file = 'spec_file'
          gem_file  = 'gem_file'
          RPM::Spec.should_receive(:file_satisfies?)
                   .with(spec_file, gem_file)
                   .and_return(false)

          gem = Polisher::Gem.new
          gem.should_receive(:file_paths).and_return([gem_file])
          gem.has_file_satisfied_by?(spec_file).should be_false
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
      it "returns list of file paths in gem" do
        gem = described_class.new
        gem.should_receive(:each_file).and_yield('file1').and_yield('file2')
        gem.file_paths.should == %w(file1 file2)
      end
    end
  end # describe Gem
end # module Polisher
