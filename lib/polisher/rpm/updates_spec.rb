# RPM Updates Spec Module
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/logger'

module Polisher
  module RPM
    module UpdatesSpec
      # Update RPM::Spec metadata to new gem
      #
      # @param [Polisher::Gem] new_source new gem to update rpmspec to
      def update_to(new_source)
        update_deps_from(new_source)
        update_files_from(new_source)
        update_metadata_from(new_source)
        update_contents
      end

      private

      # Update spec dependencies from new source
      def update_deps_from(new_source)
        @metadata[:requires] =
          non_gem_requirements +
          extra_gem_requirements(new_source) +
          new_source.deps.select { |r| !excludes_dep?(r.name) }
                    .collect { |r| RPM::Requirement.from_gem_dep(r) }.flatten

        @metadata[:build_requires] =
          non_gem_build_requirements +
          extra_gem_build_requirements(new_source) +
          new_source.dev_deps.select { |r| !excludes_dev_dep?(r.name) }
                    .collect { |r| RPM::Requirement.from_gem_dep(r, true) }.flatten
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
          pkg = gem_name if pkg.nil?
          if Gem.ignorable_file?(gem_file)
            @metadata[:pkg_excludes] ||= []
            @metadata[:pkg_excludes][pkg] << gem_file.rpmize

          elsif Gem.doc_file?(gem_file)
            @metadata[:new_files]['doc'] ||= []
            @metadata[:new_files]['doc'] << gem_file.rpmize

          else
            @metadata[:new_files][pkg] ||= []
            @metadata[:new_files][pkg] << gem_file.rpmize
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
* #{Time.now.strftime("%a %b %d %Y")} #{RPM::Spec.current_author} - #{@metadata[:version]}-1
- Upda to version #{new_source.version}
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

      def changelog_index
        @metadata[:contents].index RPM::Spec::SPEC_CHANGELOG_MATCHER
      end

      def changelog_end_index
        ci = changelog_index
        ci.nil? ? (@metadata[:contents].length - 1) :
                  (@metadata[:contents].index "\n", ci) + 1
      end

      def update_changelog
        # add changelog entry
        cei = changelog_end_index
        @metadata[:contents] = @metadata[:contents][0...cei] +
                               @metadata[:changelog_entries].join("\n\n")
      end

      def requires_contents
        @metadata[:requires].collect { |r| "Requires: #{r.str}" }.join("\n")
      end

      def build_requires_contents
        @metadata[:build_requires].collect { |r| "BuildRequires: #{r.str}" }
                                  .join("\n")
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
        ri < bri ? ri : bri
      end

      def subpkg_index
        @metadata[:contents].index RPM::Spec::SPEC_SUBPACKAGE_MATCHER || -1
      end

      def last_requires_index
        @metadata[:contents].rindex RPM::Spec::SPEC_REQUIRES_MATCHER, subpkg_index
      end

      def last_build_requires_index
        @metadata[:contents].rindex RPM::Spec::SPEC_BUILD_REQUIRES_MATCHER, subpkg_index
      end

      def last_requirement_index
        lri  = last_requires_index
        lbri = last_build_requires_index
        lri > lbri ? lri : lbri
      end

      def requirement_section_end_index
        @metadata[:contents].index "\n", last_requirement_index
      end

      def update_requires
        new_contents = requires_contents + "\n" + build_requires_contents
        rsi  = requirement_section_index
        @metadata[:contents].slice!(rsi...requirement_section_end_index)
        @metadata[:contents].insert rsi, new_contents
      end

      def new_files_contents_for(pkg)
        title = pkg == gem_name ? "%files\n" : "%files #{pkg}\n"
        contents = @metadata[:new_files][pkg].join("\n") + "\n"
        title + contents
      end

      def new_subpkg_files_contents
        @metadata[:new_files].keys
          .select { |pkg| pkg != gem_name }
          .collect { |pkg| new_files_contents_for(pkg) }.join("\n\n") + "\n\n"
      end

      def excludes_contents
        @metadata[:pkg_excludes][gem_name]
          .collect { |exclude| "%exclude #{exclude}" }
          .join("\n") + "\n\n"
      end

      def files_index
        @metadata[:contents].index RPM::Spec::SPEC_FILES_MATCHER
      end

      def files_end_index
        @metadata[:contents].index RPM::Spec::SPEC_CHANGELOG_MATCHER
      end

      def update_files
        # update files
        fi = files_index
        @metadata[:contents].slice!(fi...files_end_index)

        contents = new_files_contents_for(gem_name) +
                   excludes_contents +
                   new_subpkg_files_contents

        @metadata[:contents].insert fi, contents
      end

      def update_contents
        update_metadata_contents
        update_changelog
        update_requires
        update_files
      end
    end # module UpdatesSpec
  end # module RPM
end # module Polisher
