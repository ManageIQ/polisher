# Polisher RPM Spec Specs
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'
require 'polisher/gem'

module Polisher::RPM
  describe Spec do
    describe "#initialize" do
      it "sets gem metadata" do
        spec = described_class.new :version => '1.0.0'
        spec.metadata.should == {:version => '1.0.0'}
      end
    end
  
    describe "#method_missing" do
      it "proxies lookup to metadata" do
        spec = described_class.new :version => '1.0.0'
        spec.version.should == '1.0.0'
      end
    end

    describe "#files" do
      it "returns flattened files in all packages" do
        spec = described_class.new :pkg_files => {'foo' => ['file1'],
                                                  'doc' => ['docfile']}
        spec.files.should == %w(file1 docfile)
      end
    end

    describe "#subpkg_containing" do
      it "returns subpackage containing specified file" do
        spec = described_class.new :pkg_files => {'foo' => ['file1']}
        spec.subpkg_containing('file1').should == 'foo'
      end

      context "no subpackage contains specified file" do
        it "returns nil" do
          spec = described_class.new :pkg_files => {}
          spec.subpkg_containing('anything').should be_nil
        end
      end
    end

    describe "#upstream_gem" do
      it "sets & returns upstream gem" do
        gem_name = 'polisher'
        version  = 5.0
        gem = Polisher::Gem.new
        Polisher::Gem.should_receive(:from_rubygems)
                     .with(gem_name, version)
                     .and_return(gem)
        spec = described_class.new :gem_name => gem_name, :version => version
        spec.upstream_gem.should == gem
        spec.upstream_gem.object_id.should == spec.upstream_gem.object_id
      end
    end
  
    describe "#has_check?" do
      context "package spec has %check section" do
        it "returns true" do
          spec = described_class.new :has_check => true
          spec.has_check?.should be_true
        end
      end
  
      context "package spec does not have a %check section" do
        it "returns false" do
          spec = described_class.new
          spec.has_check?.should be_false
        end
      end
    end
  
    describe "#requirements_for_gem" do
      it "returns requirements for specified gem name" do
        spec = described_class.new :requires =>
          [Requirement.new(:name => 'rubygem(rake)')]
        spec.requirements_for_gem('rake').should == [spec.requires.first]
      end
  
      context "spec has no requirement with specified name" do
        it "returns empty array" do
          spec = described_class.new
          spec.requirements_for_gem('rake').should be_empty
        end
      end
    end

    describe "#build_requirements_for_gem" do
      it "returns build requirements for specified gem name" do
        spec = described_class.new :build_requires => [Requirement.new(:name => 'rubygem(rake)')]
        spec.build_requirements_for_gem('rake').should == [spec.build_requires.first]
      end
  
      context "spec has no requirement with specified name" do
        it "returns empty array" do
          spec = described_class.new
          spec.build_requirements_for_gem('rake').should be_empty
        end
      end
    end

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

    describe "#parse" do
      before(:each) do
        @spec  = Polisher::Test::RPM_SPEC
      end
  
      it "returns new rpmspec instance" do
        pspec = described_class.parse @spec[:contents]
        pspec.should be_an_instance_of(described_class)
      end
  
      it "parses contents from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.contents.should == @spec[:contents]
      end
  
      it "parses name from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.gem_name.should == @spec[:name]
      end
  
      it "parses version from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.version.should == @spec[:version]
      end
  
      it "parses release from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.release.should == @spec[:release]
      end
  
      it "parses requires from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.requires.should == @spec[:requires]
      end
  
      it "parses build requires from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.build_requires.should == @spec[:build_requires]
      end
  
      it "parses changelog from spec"
  
      it "parses unrpmized files from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.pkg_files.should == @spec[:files]
      end
  
      it "parses %check from spec" do
        pspec = described_class.parse @spec[:contents]
        pspec.has_check?.should be_true
  
        pspec = described_class.parse ""
        pspec.has_check?.should be_false
      end
    end
  
    describe "#update_to" do
      it "updates dependencies from gem" do
        spec = described_class.new :requires       => [Requirement.parse('rubygem(rake)'),
                                                       Requirement.parse('rubygem(activerecord)')],
                                   :build_requires => [],
                                   :contents       => ""
        gem  = Polisher::Gem.new :deps => [::Gem::Dependency.new('rake'),
                                           ::Gem::Dependency.new('rails', '~> 10')],
                                 :dev_deps => [::Gem::Dependency.new('rspec', :development)]
  
        # stub out a few methods
        spec.should_receive(:excluded_deps).at_least(:once).and_return([])
        spec.should_receive(:excluded_dev_deps).at_least(:once).and_return([])
        spec.should_receive(:update_files_from)
        spec.should_receive(:update_contents)

        spec.update_to(gem)
          spec.requires.should == [Requirement.parse('rubygem(activerecord)'),
                                   Requirement.parse('rubygem(rake) >= 0'),
                                   Requirement.parse('rubygem(rails) => 10'),
                                   Requirement.parse('rubygem(rails) < 11')]
        spec.build_requires.should == [Requirement.parse('rubygem(rspec) >= 0', :br => true)]
      end
  
      it "adds new files from gem not excluded from old gem" do
        spec = described_class.new :pkg_files => {'pkg' => ['/foo']},
                                   :gem_name  => 'gem', :version => 1,
                                   :contents  => ""
        gem  = Polisher::Gem.new
        spec.should_receive(:upstream_gem).at_least(:once).and_return(gem)
        spec.stub(:update_contents) # stub out contents update
        gem.should_receive(:file_paths).at_least(:once).
            and_return(['/foo', '/foo/bar', '/baz'])
        spec.update_to(gem)
        spec.new_files.should == {"pkg" => ['%{gem_instdir}//foo']}
      end
  
      it "updates metadata from gem" do
        spec = described_class.new :contents => ""
        gem  = Polisher::Gem.new :version => '1.0.0'
        spec.should_receive(:update_files_from) # stub out files update
        spec.should_receive(:update_contents) # stub out contents update
        spec.update_to(gem)
        spec.version.should == '1.0.0'
        spec.release.should == '1%{?dist}'
      end
  
      it "adds changelog entry"
    end
  
    describe "#to_string" do
      it "returns string representation of spec"
    end
  
    describe "#compare" do
      it "returns requirements in spec but not in gem" do
        req  = Requirement.parse 'rubygem(rails) > 3.0.0'
        spec = described_class.new :requires => [req]
        gem  = Polisher::Gem.new
  
        spec.compare(gem).should ==
          {:same => {}, :diff => {'rails' =>
                  {:spec => '> 3.0.0', :upstream => nil}}}
      end
  
      it "returns requirements in gem but not in spec" do
        req = ::Gem::Dependency.new('rails', '> 3.0.0')
        spec = described_class.new
        gem  = Polisher::Gem.new :deps => [req]
  
        spec.compare(gem).should ==
          {:same => {}, :diff => {'rails' =>
                  {:spec => nil, :upstream => '> 3.0.0'}}}
      end
  
      it "returns shared requirements with different specifiers" do
        greq = ::Gem::Dependency.new('rails', '< 5.0.0')
        gem  = Polisher::Gem.new :deps => [greq]
  
        sreq = Requirement.parse 'rubygem(rails) > 3.0.0'
        spec = described_class.new :requires => [sreq]
  
        spec.compare(gem).should ==
          {:same => {}, :diff => {'rails' =>
                  {:spec => '> 3.0.0', :upstream => '< 5.0.0'}}}
      end
  
      it "returns shared requirements" do
        greq = ::Gem::Dependency.new('rails', '< 3.0.0')
        gem  = Polisher::Gem.new :deps => [greq]
  
        sreq = Requirement.parse 'rubygem(rails) < 3.0.0'
        spec = described_class.new :requires => [sreq]
  
        spec.compare(gem).should ==
          {:diff => {}, :same => {'rails' =>
                  {:spec => '< 3.0.0', :upstream => '< 3.0.0'}}}
      end
    end
  end # describe Spec
end # module Polisher::RPM
