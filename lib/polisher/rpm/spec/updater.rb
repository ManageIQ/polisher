# RPM Spec Updater Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/rpm'

module Polisher
  module RPM
    module SpecUpdater
      # Update RPM::Spec metadata to new gem
      #
      # @param [Polisher::Gem] new_source new gem to update rpmspec to
      def update_to(new_source, update_args={})
        update_deps_from(new_source, update_args)
        update_files_from(new_source)
        update_metadata_from(new_source)
        update_contents
        contents
      end

      # Return updated spec requirements
      def updated_requires_for(new_source, update_args={})
        new_gem_requirements = new_source.deps.select  { |r| !excludes_dep?(r.name) }
                                              .collect { |r| RPM::Requirement.from_gem_dep(r) }
                                              .flatten
            gem_requirements = extra_gem_requirements(new_source) + new_gem_requirements
        non_gem_requirements + (update_args[:skip_gem_deps] ? [] : gem_requirements)
      end

      # Return updated spec build requires
      def updated_build_requires_for(new_source, update_args={})
        new_gem_requirements = new_source.dev_deps.select  { |r| !excludes_dev_dep?(r.name) }
                                                  .collect { |r| RPM::Requirement.from_gem_dep(r, true) }
                                                  .flatten
            gem_requirements = extra_gem_build_requirements(new_source) + new_gem_requirements
        non_gem_build_requirements + gem_requirements
      end

      def changelog_index
        @metadata[:contents].index RPM::Spec::SPEC_CHANGELOG_MATCHER
      end

      def changelog_end_index
        ci = changelog_index
        ci.nil? ? (@metadata[:contents].length - 1) :
                  (@metadata[:contents].index "\n", ci) + 1
      end

      def requires_contents
        crs = @metadata[:conditions].collect { |condition|
          condition.has_requires? ? condition.expanded_requires : nil
        }.compact.join("\n")

        additional = RPM::Condition.extra_requires(@metadata[:conditions],
                                                   @metadata[:requires])
        ars = additional.collect { |r| "Requires: #{r.str}" }.join("\n")

        ars + "\n" + crs
      end

      def build_requires_contents
        crs = @metadata[:conditions].collect { |condition|
          condition.has_build_requires? ? condition.expanded_build_requires : nil
        }.compact.join("\n")

        additional = RPM::Condition.extra_build_requires(@metadata[:conditions],
                                                         @metadata[:build_requires])
        ars = additional.collect { |r| "BuildRequires: #{r.str}" }.join("\n")

        ars + "\n" + crs
      end

      def first_requires_index
        @metadata[:contents].index RPM::Spec::SPEC_REQUIRES_MATCHER
      end

      def first_build_requires_index
        @metadata[:contents].index RPM::Spec::SPEC_BUILD_REQUIRES_MATCHER
      end

      def requirement_section_index
        ri   = first_requires_index
        bri  = first_build_requires_index

        # Requires missing (e.g. section is auto-generated)
        return bri unless ri
        ri < bri ? ri : bri
      end

      # Main package ends either with subpkg specification
      # or with a %description or %prep section
      def last_main_package_index
        description_index || subpkg_index || prep_index || -1
      end

      def description_index
        @metadata[:contents].index RPM::Spec::SPEC_DESCRIPTION_MATCHER
      end

      def prep_index
        @metadata[:contents].index RPM::Spec::SPEC_PREP_MATCHER
      end

      def subpkg_index
        @metadata[:contents].index RPM::Spec::SPEC_SUBPACKAGE_MATCHER
      end

      def last_requires_index
        @metadata[:contents].rindex(RPM::Spec::SPEC_REQUIRES_MATCHER, last_main_package_index) || -1
      end

      def last_build_requires_index
        @metadata[:contents].rindex(RPM::Spec::SPEC_BUILD_REQUIRES_MATCHER, last_main_package_index) || -1
      end

      def last_requirement_index
        lri  = last_requires_index
        lbri = last_build_requires_index
        lri > lbri ? lri : lbri
      end

      def requirement_section_end_index
        @metadata[:contents].index "\n", last_requirement_index
      end

      def new_files_contents_for(pkg)
        has_new_files = @metadata.key?(:new_files) && @metadata[:new_files].key?(pkg)
        return "" unless has_new_files

        title = pkg == full_name ? "%files\n" : "%files #{pkg}\n"
        contents = @metadata[:new_files][pkg].join("\n")
        title + contents
      end

      def new_subpkg_files_contents
        has_new_files = @metadata.key?(:new_files)
        return "" unless has_new_files

        @metadata[:new_files].keys
          .select  { |pkg| pkg != full_name }
          .collect { |pkg|
            [new_files_contents_for(pkg), excludes_contents_for(name)]
          }.flatten.join("\n") + "\n\n"
      end

      def excludes_contents_for(name)
        if @metadata[:pkg_excludes][name]
          @metadata[:pkg_excludes][name]
            .collect { |exclude| "%exclude #{exclude}" }
            .join("\n")
        else
          ''
        end
      end

      def files_index
        @metadata[:contents].index RPM::Spec::SPEC_FILES_MATCHER
      end

      def files_end_index
        @metadata[:contents].index RPM::Spec::SPEC_CHANGELOG_MATCHER
      end

      private

      def update_requires
        new_contents = (requires_contents + "\n" + build_requires_contents).strip + "\n\n"
        @metadata[:contents].gsub!(Spec::SPEC_REQUIRES_MATCHER, "")
        @metadata[:contents].gsub!(Spec::SPEC_BUILD_REQUIRES_MATCHER, "")
        @metadata[:contents].insert last_main_package_index, new_contents
      end


      def update_files
        # update files
        fi  = files_index || files_end_index || length
        fei = files_end_index
        @metadata[:contents].slice!(fi...files_end_index) unless fei.nil?

        contents = new_files_contents_for(full_name) + "\n"   +
                   excludes_contents_for(full_name)  + "\n\n" +
                   new_subpkg_files_contents

        @metadata[:contents].insert fi, contents
      end

      # Update spec dependencies from new source
      def update_deps_from(new_source, update_args={})
        update_requires_from       new_source, update_args
        update_build_requires_from new_source, update_args
      end

      # Update requires from new source
      def update_requires_from(new_source, update_args={})
        @metadata[:requires] = updated_requires_for(new_source, update_args)
      end

      # Update build requires from new source
      def update_build_requires_from(new_source, update_args={})
        @metadata[:build_requires] = updated_build_requires_for(new_source, update_args)
      end

      # Internal helper to update spec files from new source
      def update_files_from(new_source)
        # populate file list from rpmized versions of new source files
        # minus excluded files minus duplicates (files taken care by other
        # dirs on list)
        #
        # TODO: also detect / add files from SOURCES & PATCHES
        gem_files = new_source.file_paths - excluded_files
        gem_files.reject! do |file|
          gem_files.any? do |other|
            other != file && self.class.file_satisfies?(other, file)
          end
        end

        @metadata[:new_files] = {}
        @metadata[:pkg_excludes] ||= {}
        gem_files.each do |gem_file|
          pkg = subpkg_containing(gem_file)
          pkg = full_name if pkg.nil?
          if Gem.ignorable_file?(gem_file)
            @metadata[:pkg_excludes][pkg] ||= []
            @metadata[:pkg_excludes][pkg] << gem_file.rpmize

          elsif Gem.runtime_file?(gem_file) || Gem.license_file?(gem_file)
            @metadata[:new_files][pkg] ||= []
            @metadata[:new_files][pkg] << gem_file.rpmize

          # All files not required for runtime should go
          # into -doc subpackage if -doc subpackage exists
          else
            package = has_doc_subpkg? ? 'doc' : pkg

            @metadata[:new_files][package] ||= []
            @metadata[:new_files][package] << gem_file.rpmize
          end
        end

        extra_gem_files.each do |pkg, files|
          @metadata[:new_files][pkg] ||= []
          @metadata[:new_files][pkg]  += files.collect { |file| file.rpmize }
        end
      end

      # Internal helper to update spec metadata from new source
      def update_metadata_from(new_source)
        # update to new version
        @metadata[:version] = new_source.version
        @metadata[:release] = "1%{?dist}"

        # invalidate the local gem
        @update_gem = true

        # add changelog entry
        changelog_entry = <<EOS
* #{Time.now.strftime("%a %b %d %Y")} #{RPM.current_author} - #{@metadata[:version]}-1
- Update #{@metadata[:full_name]} to version #{new_source.version}
EOS
        @metadata[:changelog_entries] ||= []
        @metadata[:changelog_entries].unshift changelog_entry.rstrip
      end

      def update_metadata_contents
        # replace version / release
        @metadata[:contents].gsub!(RPM::Spec::SPEC_VERSION_MATCHER,
                                   "Version: #{@metadata[:version]}")
        @metadata[:contents].gsub!(RPM::Spec::SPEC_RELEASE_MATCHER,
                                   "Release: #{@metadata[:release]}")
      end

      def update_changelog
        # add changelog entry
        cei = changelog_end_index
        @metadata[:contents] = @metadata[:contents][0...cei] +
                               @metadata[:changelog_entries].join("\n\n")
      end

      def sanitize_contents
        # reasonably compact newlines
        @metadata[:contents].gsub!(/[\n]{3,}/, "\n\n")

        # remove empty conditionals
        @metadata[:contents].gsub!(/%if[^\n]*\n+%endif\n/, "")
      end

      def update_contents
        update_metadata_contents
        update_changelog
        update_requires
        update_files
        sanitize_contents
      end
    end # module SpecUpdater
  end # module RPM
end # module Polisher
