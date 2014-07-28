# RPM Parses Spec Module
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/logger'

module Polisher
  module RPM
    module ParsesSpec
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Parse the specified rpm spec and return new RPM::Spec instance from metadata
        #
        # @param [String] string contents of spec to parse
        # @return [Polisher::RPM::Spec] spec instantiated from rpmspec metadata
        def parse(spec)
          in_subpackage = false
          in_changelog  = false
          in_files      = false
          subpkg_name   = nil
          meta = {:contents => spec}
          spec.each_line { |l|
            if l =~ RPM::Spec::COMMENT_MATCHER
              ;

            # TODO support optional gem prefix
            elsif l =~ RPM::Spec::GEM_NAME_MATCHER
              meta[:gem_name] = $1.strip
              meta[:gem_name] = $1.strip

            elsif l =~ RPM::Spec::SPEC_NAME_MATCHER &&
                  $1.strip != "%{gem_name}"
              meta[:gem_name] = $1.strip

            elsif l =~ RPM::Spec::SPEC_VERSION_MATCHER
              meta[:version] = $1.strip

            elsif l =~ RPM::Spec::SPEC_RELEASE_MATCHER
              meta[:release] = $1.strip

            elsif l =~ RPM::Spec::SPEC_SUBPACKAGE_MATCHER
              subpkg_name = $1.strip
              in_subpackage = true

            elsif l =~ RPM::Spec::SPEC_REQUIRES_MATCHER &&
                  !in_subpackage
              meta[:requires] ||= []
              meta[:requires] << RPM::Requirement.parse($1.strip)

            elsif l =~ RPM::Spec::SPEC_BUILD_REQUIRES_MATCHER &&
                  !in_subpackage
              meta[:build_requires] ||= []
              meta[:build_requires] << RPM::Requirement.parse($1.strip)

            elsif l =~ RPM::Spec::SPEC_CHANGELOG_MATCHER
              in_changelog = true

            elsif l =~ RPM::Spec::SPEC_FILES_MATCHER
              subpkg_name = nil
              in_files = true

            elsif l =~ RPM::Spec::SPEC_SUBPKG_FILES_MATCHER
              subpkg_name = $1.strip
              in_files = true

            elsif l =~ RPM::Spec::SPEC_CHECK_MATCHER
              meta[:has_check] = true

            elsif in_changelog
              meta[:changelog] ||= ""
              meta[:changelog] << l

            elsif in_files
              tgt = subpkg_name.nil? ? meta[:gem_name] : subpkg_name

              if l =~ RPM::Spec::SPEC_EXCLUDED_FILE_MATCHER
                sl = Regexp.last_match(1)
                meta[:pkg_excludes] ||= {}
                meta[:pkg_excludes][tgt] ||= []
                meta[:pkg_excludes][tgt] << sl unless sl.blank?

              else
                sl = l.strip
                meta[:pkg_files] ||= {}
                meta[:pkg_files][tgt] ||= []
                meta[:pkg_files][tgt] << sl unless sl.blank?

              end
            end
          }

          # Ensure pkg_files hash exists
          meta[:pkg_files] ||= {}

          meta[:changelog_entries] = meta[:changelog] ?
                                     meta[:changelog].split("\n\n") : []
          meta[:changelog_entries].collect! { |c| c.strip }.compact!

          self.new meta
        end

      end # module ClassMethods
    end # module ParsesSpec
  end # module RPM
end # module Polisher
