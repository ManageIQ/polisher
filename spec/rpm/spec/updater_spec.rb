#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
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
        spec = described_class.new :pkg_files => {'doc' => ['/foo']},
                                   :gem_name  => 'gem', :version => 1,
                                   :contents  => ""
        gem  = Polisher::Gem.new
        spec.should_receive(:upstream_gem).at_least(:once).and_return(gem)
        spec.stub(:update_contents) # stub out contents update
        gem.should_receive(:file_paths).at_least(:once).
            and_return(['/foo', '/foo/bar', '/baz'])
        spec.update_to(gem)
        spec.new_files.should == {"doc" => ['%{gem_instdir}//foo']}
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
  end # describe Spec
end # module Polisher::RPM
