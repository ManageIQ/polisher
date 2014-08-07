# Polisher RPM UpdatesSpec Spec
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/updates_spec'
require 'polisher/gem'

module Polisher::RPM
  describe UpdatesSpec do
    describe "#update_to" do
      before(:all) do
        gemfile = File.expand_path(File.join(File.dirname(__FILE__), '../data/activesupport-4.1.4.gem'))
        @source = Polisher::Upstream.parse(gemfile)
        @gemfile = gemfile
      end

      it "updates files only in the main package for packages without -doc subpkg" do
        rpmspec = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../data/rubygem-activesupport.spec')))
        rpmspec = Polisher::RPM::Spec.parse rpmspec
        rpmspec.gem = @source
        rpmspec.update_to @source

        rpmspec.metadata[:new_files].should == {"activesupport"=>
                                                 ["%doc %{gem_instdir}/CHANGELOG.md",
                                                  "%doc %{gem_instdir}/MIT-LICENSE",
                                                  "%doc %{gem_instdir}/README.rdoc",
                                                  "%{gem_libdir}",
                                                  "%dir %{gem_instdir}",
                                                  "%doc %{gem_docdir}",
                                                  "%{gem_cache}",
                                                  "%{gem_spec}",
                                                  "%{gem_instdir}/test"]}

        rpmspec.metadata[:pkg_excludes].should == {}

        rpmspec.metadata[:pkg_files].should == {"activesupport"=>
                                                 ["%dir %{gem_instdir}",
                                                  "%doc %{gem_instdir}/CHANGELOG.md",
                                                  "%{gem_libdir}",
                                                  "%doc %{gem_instdir}/MIT-LICENSE",
                                                  "%doc %{gem_instdir}/README.rdoc",
                                                  "%doc %{gem_docdir}",
                                                  "%{gem_cache}",
                                                  "%{gem_spec}",
                                                  "%{gem_instdir}/test"]}
      end

      it "updates files in the main pkg and doc subpkg" do
        rpmspec = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../data/rubygem-activesupport-with-doc.spec')))

        rpmspec = Polisher::RPM::Spec.parse rpmspec
        rpmspec.gem = @source
        rpmspec.update_to @source

        rpmspec.metadata[:new_files].should == {"doc"=>
                                                 ["%doc %{gem_instdir}/CHANGELOG.md",
                                                  "%doc %{gem_instdir}/README.rdoc",
                                                  "%doc %{gem_docdir}",
                                                  "%{gem_instdir}/test"],
                                                "activesupport"=>
                                                 ["%doc %{gem_instdir}/MIT-LICENSE",
                                                  "%{gem_libdir}",
                                                  "%dir %{gem_instdir}",
                                                  "%{gem_cache}",
                                                  "%{gem_spec}"]}

        rpmspec.metadata[:pkg_files].should == {"activesupport"=>
                                                 ["%dir %{gem_instdir}",
                                                  "%doc %{gem_instdir}/CHANGELOG.md",
                                                  "%{gem_libdir}",
                                                  "%doc %{gem_instdir}/MIT-LICENSE",
                                                  "%doc %{gem_instdir}/README.rdoc",
                                                  "%{gem_cache}",
                                                  "%{gem_spec}"],
                                                "doc"=>
                                                 ["%doc %{gem_docdir}",
                                                  "%{gem_instdir}/test"]}
      end

      it "updates only build requires as requires are auto-generated" do
        rpmspec = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../data/rubygem-activesupport-without-requires.spec')))

        rpmspec = Polisher::RPM::Spec.parse rpmspec
        rpmspec.gem = @source
        rpmspec.update_to @source

        rpmspec.metadata[:requires].should == []
      end
    end
  end
end
