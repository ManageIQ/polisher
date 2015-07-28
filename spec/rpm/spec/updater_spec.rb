#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'
require 'polisher/rpm/requirement'
require 'polisher/gem'

module Polisher::RPM
  describe Spec do
    let(:gem) do
      Polisher::Gem.new :path => local_gem.gem_path
    end

    let(:spec) do
      spec = described_class.new 
      spec.gem = gem
      spec
    end

    describe "#update_to" do
      it "updates dependencies" do
        spec.should_receive(:update_deps_from).with(gem)
        spec.update_to(gem)
      end

      it "updates files" do
        spec.should_receive(:update_files_from).with(gem)
        spec.update_to(gem)
      end

      it "updates metadata" do
        spec.should_receive(:update_metadata_from).with(gem)
        spec.update_to(gem)
      end

      it "updates contents" do
        spec.should_receive(:update_contents)
        spec.update_to(gem)
      end
    end

    describe "#updated_requires_for" do
      it "returns array of updated requires" do
        spec.updated_requires_for(gem).should be_an_instance_of(Array)
      end

      it "returns non gem requirements" do
        expected = ['non', 'gem', 'reqs']
        spec.should_receive(:non_gem_requirements).and_return(expected)
        result = spec.updated_requires_for(gem)
        expected.each { |req| result.should include(req) }
      end

      it "returns extra gem requirements" do
        expected = ['extra', 'gem', 'reqs']
        spec.should_receive(:extra_gem_requirements)
            .with(gem).and_return(expected)
        result = spec.updated_requires_for(gem)
        expected.each { |req| result.should include(req) }
      end

      it "returns new source dependencies" do
        gem.deps = gem_json.deps
        spec.should_receive(:excludes_dep?)
            .exactly(gem.deps.length).times.and_return(false)
        expected = gem.deps.collect { |d| Requirement.from_gem_dep(d) }.flatten
        result = spec.updated_requires_for(gem)
        expected.each { |req| result.should include(req) }
      end

      context "spec excludes new source dep" do
        it "does not return it" do
          gem.deps = gem_json.deps
          spec.should_receive(:excludes_dep?)
              .with(gem.deps.first.name).and_return(true)
          spec.should_receive(:excludes_dep?)
              .exactly(gem.deps.length-1).times.and_return(false)
          result = spec.updated_requires_for(gem)
          result.any? { |req| req.matches?(gem.deps.first) }.should be_false
        end
      end
    end

    describe "#updated_build_requires_for" do
      it "returns array of updated build requires" do
        spec.updated_build_requires_for(gem).should be_an_instance_of(Array)
      end

      it "returns non gem build requirements" do
        expected = ['non', 'gem', 'reqs']
        spec.should_receive(:non_gem_build_requirements).and_return(expected)
        result = spec.updated_build_requires_for(gem)
        expected.each { |req| result.should include(req) }
      end

      it "returns extra gem build requirements" do
        expected = ['extra', 'gem', 'reqs']
        spec.should_receive(:extra_gem_build_requirements)
            .with(gem).and_return(expected)
        result = spec.updated_build_requires_for(gem)
        expected.each { |req| result.should include(req) }
      end

      it "returns new source dev dependencies" do
        gem.dev_deps = gem_json.deps
        spec.should_receive(:excludes_dev_dep?)
            .exactly(gem.dev_deps.length).times.and_return(false)
        expected = gem.dev_deps.collect { |d| Requirement.from_gem_dep(d, true) }.flatten
        result = spec.updated_build_requires_for(gem)
        expected.each { |req| result.should include(req) }
      end

      context "spec excludes new source dev dep" do
        it "does not return it" do
          gem.dev_deps = gem_json.deps
          spec.should_receive(:excludes_dev_dep?)
              .with(gem.dev_deps.first.name).and_return(true)
          spec.should_receive(:excludes_dev_dep?)
              .exactly(gem.dev_deps.length-1).times.and_return(false)
          result = spec.updated_build_requires_for(gem)
          result.any? { |req| req.matches?(gem.dev_deps.first) }.should be_false
        end
      end
    end

    describe "#changelog_index" do
      it "returns position of the changelog in spec" do
        spec.contents = "blah\nblah\n%changelog\nmore" 
        spec.changelog_index.should == 10
      end
    end

    describe "#changelog_end_index" do
      it "returns position of the end of the changelog in spec" do
        spec.contents = "blah\nblah\n%changelog\nmore"
        spec.changelog_end_index.should == 21
      end

      context "no changelog in spec" do
        it "returns the last position in the spec" do
          contents = "blah\nblah"
          spec.contents = contents
          spec.changelog_end_index.should == contents.length - 1
        end
      end
    end

    describe "#requires_contents" do
      it "returns generated spec Requires from metadata" do
        spec.requires = rpm_spec.requires
        expected = spec.requires.collect { |r| "Requires: #{r.str}" }.join("\n")
        spec.requires_contents.should == expected
      end
    end

    describe "#build_requires_contents" do
      it "returns generated spec BuildRequires from metadata" do
        spec.build_requires = rpm_spec.build_requires
        expected = spec.build_requires.collect { |r| "BuildRequires: #{r.str}" }.join("\n")
        spec.build_requires_contents.should == expected
      end
    end

    describe "#first_requires_index" do
      it "returns the position of the first requires in the spec" do
        spec.contents = "blah\nRequires: foo\nRequires: bar\nother" 
        spec.first_requires_index.should == 5

        spec.contents = ""
        spec.first_requires_index.should be_nil
      end
    end

    describe "#first_build_requires_index" do
      it "returns the position of the first build requires in the spec" do
        spec.contents = "blah\nRequires: foo\nBuildRequires: bar\nBuildRequires: baz\nother"
        spec.first_build_requires_index.should == 19

        spec.contents = ""
        spec.first_build_requires_index.should be_nil
      end
    end

    describe "#requirement_section_index" do
      context "no Requires" do
        it "returns index of first build requires" do
          spec.contents = "blah\nBuildRequires: bar\nBuildRequires: baz\nother"
          spec.requirement_section_index.should == 5

          spec.contents = ""
          spec.requirement_section_index.should be_nil
        end
      end

      context "first Requires is before first BuildRequires" do
        it "returns index of first requires" do
          spec.contents = "blah\nRequires: bar\nBuildRequires: baz\nother"
          spec.requirement_section_index.should == 5
        end
      end

      context "first BuildRequires is before first Requires" do
        it "returns index of first BuildRequires" do
          spec.contents = "blah\nBuildRequires: bar\nRequires: baz\nother" 
          spec.requirement_section_index.should == 5
        end
      end
    end

    describe "#last_main_package_index" do
      context "spec has description section" do
        it "returns position of description section" do
          spec.contents = "blah\nmore\n%description\ninfo\nmore" 
          spec.last_main_package_index.should == 10
        end
      end

      context "spec has at least one subpkg" do
        it "returns position of first subpackage" do
          spec.contents = "blah\nmore\n%package foo\ninfo\nmore"
          spec.last_main_package_index.should == 10
        end
      end
      
      context "spec has a prep section" do
        it "returns position of prep section" do
          spec.contents = "metadata\nmore\n%prep\ncmd\nantoher"
          spec.last_main_package_index.should == 14
        end
      end

      context "no description, subpackages, prep sections" do
        it "returns -1" do
          spec.contents = ""
          spec.last_main_package_index.should == -1
        end
      end
    end

    describe "#description_index" do
      it "returns position of description section" do
        spec.contents = "meta\ndata\n%description\ndescript\n"
        spec.description_index.should == 10
      end
    end

    describe "#prep_index" do
      it "returns position of prep section" do
        spec.contents = "foo\n%prep\nbar"
        spec.prep_index.should == 4
      end
    end

    describe "#subpkg_index" do
      it "returns position of the first subpackage" do
        spec.contents = "foo\n%package bar\nstuff\n%package baz\nmore stuff"
        spec.subpkg_index.should == 4
      end
    end

    describe "#last_requires_index" do
      it "returns the position of the last Requires in the spec" do
        spec.contents = "foo\nRequires: abc\nRequires: def\nBuildRequires: 123\nok"
        spec.last_requires_index.should == 18
      end

      context "no Requires in the spec" do
        it "returns -1" do
          spec.contents = ""
          spec.last_requires_index.should == -1
        end
      end
    end

    describe "#last_build_requires_index" do
      it "returns the position of the last BuildRequires in the spec" do
        spec.contents = "foo\nRequires: abc\nBuildRequires: def\nBuildRequires: 123\nok"
        spec.last_build_requires_index.should == 37
      end

      context "no BuildRequires in the spec" do
        it "returns -1" do
          spec.contents = ""
          spec.last_build_requires_index.should == -1
        end
      end
    end

    describe "#last_requirement_index" do
      context "last Requires is after last BuildRequires" do
        it "returns last_requires_index" do
          spec.contents = "info\nBuildRequires: br\nRequires: r\nmore stuff"
          spec.last_requirement_index.should == 23
        end
      end

      context "last BuildRequires is after last Requires" do
        it "returns last_build_requires_index" do
          spec.contents = "info\nRequires: br\nBuildRequires: r\nmore stuff"
          spec.last_requirement_index.should == 18
        end
      end
    end

    describe "#requirement_section_end_index" do
      it "returns the position of the newline following the last_requires_index" do
        spec.contents = "info\nRequires: br\nBuildRequires: r\nmore stuff"
        spec.requirement_section_end_index.should == 34
      end
    end

    describe "#new_files_contents_for" do
      it "returns generated files section for main package" do
        files = ["file1", "foobar"]
        expected = "%files\n" + files.join("\n") + "\n"
        spec.metadata[:new_files] = {spec.gem_name => files}
        spec.new_files_contents_for(spec.gem_name).should == expected
      end

      it "returns generated files section for specified subpkg" do
        files = ["file1", "foobar"]
        expected = "%files doc\n" + files.join("\n") + "\n"
        spec.metadata[:new_files] = {'doc' => files}
        spec.new_files_contents_for('doc').should == expected
      end
    end

    describe "#excludes_contents" do
      context "excludes are specified" do
        it "returns generated excluded files contents" do
          files = ['file1', 'foobar']
          expected = files.collect{ |e| "%exclude #{e}" }.join("\n") + "\n\n"
          spec.metadata[:pkg_excludes] = {spec.gem_name => files}
          spec.excludes_contents.should == expected
        end
      end

      context "excludes are not specified" do
        it "returns blank string" do
          spec.excludes_contents.should == ""
        end
      end
    end

    describe "#files_index" do
      it "returns position of files section in spec" do
        spec.contents = "lot\nof\metadata\n%files\nlist\nfile1\nfiles2"
        spec.files_index.should == 15
      end
    end

    describe "#files_end_index" do
      it "returns position of changelog section in spec" do
        spec.contents = "lot\nof\metadata\n%files\nlist\n%changelog\nentry1"
        spec.files_end_index.should == 27
      end
    end


    describe "#update_requires" do
      it "updates requirements section" do
        spec.should_receive(:requires_contents).and_return('requires_contents')
        spec.should_receive(:build_requires_contents).and_return('build_requires_contents')
        spec.contents = "foo\nRequires: bar\nBuildRequires: baz\nRequires: biz\n"
        expected = "foo\nrequires_contents\nbuild_requires_contents\n"
        spec.send(:update_requires)
        spec.contents.should == expected
      end
    end

    describe "#update_files" do
      it "tbd"
    end

    describe "#update_deps_from" do
      it "updates requires from new source" do
        spec.should_receive(:update_requires_from).with(gem)
        spec.send(:update_deps_from, gem)
      end

      it "updates build requires from new source" do
        spec.should_receive(:update_build_requires_from).with(gem)
        spec.send(:update_deps_from, gem)
      end
    end

    describe "#update_requires_from" do
      it "sets Requires from updated requires" do
        expected = ['req', 'uires']
        spec.should_receive(:updated_requires_for)
            .with(gem)
            .and_return(expected)
        spec.send(:update_requires_from, gem)
        spec.requires.should == expected
      end
    end

    describe "#update_build_requires_from" do
      it "sets BuildRequires from updated build requires" do
        expected = ['req', 'uires']
        spec.should_receive(:updated_build_requires_for)
            .with(gem)
            .and_return(expected)
        spec.send(:update_build_requires_from, gem)
        spec.build_requires.should == expected
      end
    end

    describe "#update_files_from" do
      it "tbd"
    end

    describe "#update_metadata_from" do
      it "updates version" do
        gem.version = '1.2.3'
        spec.send(:update_metadata_from, gem)
        spec.version.should == '1.2.3'
      end

      it "resets release" do
        spec.release = '1000000'
        spec.send(:update_metadata_from, gem)
        spec.release.should == '1%{?dist}'
      end

      it "invalidates local gem" do
        spec.instance_variable_set(:@update_gem, false)
        spec.send(:update_metadata_from, gem)
        spec.instance_variable_get(:@update_gem).should be_true
      end

      it "adds changelog entry" do
        spec.send(:update_metadata_from, gem)
        spec.changelog_entries.length.should == 1
      end

      it "generates valid changelog entry"
    end

    describe "#update_metadata_contents" do
      it "updates spec version and release" do
        before = "Name: foo\nVersion: 0.1\nRelease: 2?%{dist}\n%package"
        after  = "Name: foo\nVersion: 1.0\nRelease: 1?%{dist}\n%package"

        spec.metadata[:contents] = before
        spec.version             = 1.0
        spec.release             = '1?%{dist}'
        spec.send(:update_metadata_contents)
        spec.contents.should == after
      end
    end

    describe "#update_changelog" do
      it "updates the changelog in the spec" do
        spec.metadata[:changelog_entries] = ['*entry0', '*entry01']
        spec.contents = "foo\n%changelog\n*entry1\n*entry2"
        expected = "foo\n%changelog\n*entry0\n\n*entry01"
        spec.send(:update_changelog)
        spec.contents.should == expected
      end
    end

    describe "#update_contents" do
      it "updates metadata contents" do
        spec.should_receive(:update_metadata_contents)
        spec.send(:update_contents)
      end

      it "updates changelog" do
        spec.should_receive(:update_changelog)
        spec.send(:update_contents)
      end

      it "updates requires" do
        spec.should_receive(:update_requires)
        spec.send(:update_contents)
      end

      it "updates files" do
        spec.should_receive(:update_files)
        spec.send(:update_contents)
      end
    end
  end # describe Spec
end # module Polisher::RPM
