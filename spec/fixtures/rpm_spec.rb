require 'polisher/rpm/requirement'

module Polisher
  module Test
    module Fixtures
      class RpmSpec
        def path
          @path ||= "#{data_dir}/rubygem-activesupport.spec"
        end

        def contents
          @contents ||= File.read(path)
        end

        def name
          @name ||= "rubygem-%{gem_name}"
        end

        def full_name
          @full_name ||= "rubygem-activesupport"
        end

        def gem_name
          @gem_name ||= "activesupport"
        end

        def version
          @version ||= "4.0.0"
        end

        def release
          @release ||= "1%{?dist}"
        end

        def requires
          @requires ||= [Polisher::RPM::Requirement.parse("ruby(rubygems)"),
                         Polisher::RPM::Requirement.parse("ruby(release)"), 
                         Polisher::RPM::Requirement.parse("rubygem(bigdecimal)"),
                         Polisher::RPM::Requirement.parse("rubygem(dalli)"),
                         Polisher::RPM::Requirement.parse("rubygem(i18n) >= 0.6"),
                         Polisher::RPM::Requirement.parse("rubygem(i18n) < 1.0"),
                         Polisher::RPM::Requirement.parse("rubygem(minitest) >= 4.2"),
                         Polisher::RPM::Requirement.parse("rubygem(minitest) < 5"),
                         Polisher::RPM::Requirement.parse("rubygem(multi_json) >= 1.0"),
                         Polisher::RPM::Requirement.parse("rubygem(multi_json) < 2"),
                         Polisher::RPM::Requirement.parse("rubygem(rack)"),
                         Polisher::RPM::Requirement.parse("rubygem(thread_safe)"),
                         Polisher::RPM::Requirement.parse("rubygem(tzinfo) >= 0.3.37"),
                         Polisher::RPM::Requirement.parse("rubygem(tzinfo) < 0.4.0")]
        end

        def build_requires
          @build_requires ||= [Polisher::RPM::Requirement.parse("rubygems-devel"),
                               Polisher::RPM::Requirement.parse("rubygem(bigdecimal)"),
                               Polisher::RPM::Requirement.parse("rubygem(builder)"),
                               Polisher::RPM::Requirement.parse("rubygem(dalli)"),
                               Polisher::RPM::Requirement.parse("rubygem(i18n) >= 0.6"),
                               Polisher::RPM::Requirement.parse("rubygem(i18n) < 1.0"),
                               Polisher::RPM::Requirement.parse("rubygem(minitest)"),
                               Polisher::RPM::Requirement.parse("rubygem(mocha)"),
                               Polisher::RPM::Requirement.parse("rubygem(multi_json) >= 1.0"),
                               Polisher::RPM::Requirement.parse("rubygem(multi_json) < 2"),
                               Polisher::RPM::Requirement.parse("rubygem(rack)"),
                               Polisher::RPM::Requirement.parse("rubygem(thread_safe)"),
                               Polisher::RPM::Requirement.parse("rubygem(tzinfo) >= 0.3.37"),
                               Polisher::RPM::Requirement.parse("rubygem(tzinfo) < 0.4.0")]
        end

        def changelog
          @changelog ||= <<EOS
* Fri Aug 09 2013 Josef Stribny <jstribny@redhat.com> - 1:4.0.0-2
- Fix: add minitest to requires

* Tue Jul 30 2013 Josef Stribny <jstribny@redhat.com> - 1:4.0.0-1
- Update to ActiveSupport 4.0.0.

* Tue Mar 19 2013 Vit Ondruch <vondruch@redhat.com> - 1:3.2.13-1
- Update to ActiveSupport 3.2.13.
EOS
        end

        def files
          @files ||= {"rubygem-activesupport" => ["%dir %{gem_instdir}", "%doc %{gem_instdir}/CHANGELOG.md",
                                                  "%{gem_libdir}", "%doc %{gem_instdir}/MIT-LICENSE",
                                                  "%doc %{gem_instdir}/README.rdoc", "%doc %{gem_docdir}",
                                                  "%{gem_cache}", "%{gem_spec}", "%{gem_instdir}/test"]}
        end

        def [](key)
          self.send(key.intern)
        end
      end # class RpmSpec
    end # module Fixtures

    def rpm_spec
      @rpm_spec ||= Fixtures::RpmSpec.new
    end
  end # module Test
end # module Polisher
