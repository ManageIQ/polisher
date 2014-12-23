#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "::ignorable_file?" do
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

    describe "::runtime_file?" do
      context "file is a runtime file" do
        it "returns true" do
          described_class.runtime_file?('lib').should be_true
          described_class.runtime_file?('bin').should be_true
        end
      end

      context "file is not a runtime file" do
        it "returns false" do
          described_class.runtime_file?('spec').should be_false
        end
      end
    end

    describe "::license_file?" do
      context "file is a runtime file" do
        it "returns true" do
          described_class.license_file?('LICENSE').should be_true
          described_class.license_file?('LICENCE').should be_true
          described_class.license_file?('MIT-LICENSE').should be_true
        end
      end

      context "file is not a runtime file" do
        it "returns false" do
          described_class.license_file?('something').should be_false
        end
      end
    end

    describe "::doc_file?" do
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
      before do
        @gem = described_class.new :path => 'gem_path'
        @pkg = ::Gem::Installer.new 'gem_path'
        ::Gem::Installer.should_receive(:new)
                        .with('gem_path', :unpack => true)
                        .and_return(@pkg)
      end

      context "no block specified" do
        before do
          Dir.should_receive(:mktmpdir).and_return('polisher_tmpdir')
        end

        it "unpacks gem at gem_path into temp dir" do
          @pkg.should_receive(:unpack).with('polisher_tmpdir')
          @gem.unpack
        end

        it "returns tmp dir" do
          @pkg.should_receive(:unpack)
          @gem.unpack.should == 'polisher_tmpdir'
        end
      end

      context "block specified" do
        before do
          @bl = proc {}
          Dir.should_receive(:mktmpdir).and_yield('polisher_tmpdir')
        end
        it "invokes block with tmp dir" do
          @bl.should_receive(:call).with('polisher_tmpdir')
          @pkg.should_receive(:unpack).with('polisher_tmpdir')
          @gem.unpack &@bl
        end

        it "returns nil" do
          @pkg.should_receive(:unpack)
          @gem.unpack(&@bl).should be_nil
        end
      end
    end

    describe "#each_file" do
      it "invokes block with path to each file in gem" do
        gem = described_class.new
        gem.should_receive(:unpack).and_yield('unpack_dir')
        pathname = Pathname.new('unpack_dir')
        Pathname.should_receive(:new).with('unpack_dir').and_return(pathname)
        pathname.should_receive(:find)
                .and_yield('unpack_dir')
                .and_yield('unpack_dir/t1')
                .and_yield('unpack_dir/')
                .and_yield('t2')
                .and_yield('t3')
        bl = proc{}
        bl.should_receive(:call).with('t1')
        bl.should_receive(:call).with('t2')
        bl.should_receive(:call).with('t3')
        gem.each_file &bl
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
