# Polisher RPM Spec Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/core'
require 'polisher/gem'
require 'polisher/rpm/requirement'
require 'polisher/rpm/has_requirements'
require 'polisher/rpm/has_gem'
require 'polisher/rpm/has_files'
require 'polisher/rpm/updates_spec'
require 'polisher/rpm/parses_spec'
require 'polisher/rpm/compares_spec'
require 'polisher/component'

module Polisher
  module RPM
    deps = ['gem2rpm', 'versionomy', 'active_support', 'active_support/core_ext']
    Component.verify("RPM::Spec", *deps) do
      class Spec
        include HasGem
        include HasRequirements
        include HasFiles
        include UpdatesSpec
        include ParsesSpec
        include ComparesSpec

        AUTHOR = "#{ENV['USER']} <#{ENV['USER']}@localhost.localdomain>"
        COMMENT_MATCHER             = /^\s*#.*/
        GEM_NAME_MATCHER            = /^%global\s*gem_name\s(.*)$/
        SPEC_NAME_MATCHER           = /^Name:\s*#{package_prefix}-(.*)$/
        SPEC_VERSION_MATCHER        = /^Version:\s*(.*)$/
        SPEC_RELEASE_MATCHER        = /^Release:\s*(.*)$/
        SPEC_REQUIRES_MATCHER       = /^Requires:\s*(.*)$/
        SPEC_BUILD_REQUIRES_MATCHER = /^BuildRequires:\s*(.*)$/
        SPEC_GEM_REQ_MATCHER        = /^.*\s*#{requirement_prefix}\((.*)\)(\s*(.*))?$/
        SPEC_SUBPACKAGE_MATCHER     = /^%package\s(.*)$/
        SPEC_CHANGELOG_MATCHER      = /^%changelog$/
        SPEC_FILES_MATCHER          = /^%files$/
        SPEC_SUBPKG_FILES_MATCHER   = /^%files\s*(.*)$/
        SPEC_EXCLUDED_FILE_MATCHER  = /^%exclude\s+(.*)$/
        SPEC_CHECK_MATCHER          = /^%check$/

        FILE_MACRO_MATCHERS         =
          [/^%doc\s/,     /^%config\s/,  /^%attr\s/,
           /^%verify\s/,  /^%docdir.*/,  /^%dir\s/, /^%defattr.*/,
           /^%{gem_instdir}\/+/, /^%{gem_cache}/, /^%{gem_spec}/, /^%{gem_docdir}/]

        FILE_MACRO_REPLACEMENTS =
          {"%{_bindir}"    => 'bin',
           "%{gem_libdir}" => 'lib'}

        attr_accessor :metadata

        # Return the currently configured author
        def self.current_author
          ENV['POLISHER_AUTHOR'] || AUTHOR
        end

        def initialize(metadata={})
          @metadata = metadata
        end

        # Dispatch all missing methods to lookup calls in rpm spec metadata
        def method_missing(method, *args, &block)
          # proxy to metadata
          if @metadata.has_key?(method)
            @metadata[method]

          else
            super(method, *args, &block)
          end
        end

        # Return subpkg containing the specified file
        def subpkg_containing(file)
          pkg_files.each do |pkg, spec_files|
            return pkg if spec_files.include?(file)
          end
          nil
        end

        # Return boolean indicating if spec has a %check section
        def has_check?
          @metadata.has_key?(:has_check) && @metadata[:has_check]
        end

        # Return all gem requirements _not_ in the specified gem
        def extra_gem_requirements(gem)
          gem_reqs = gem.deps.collect { |d| requirements_for_gem(d.name) }.flatten
          gem_requirements - gem_reqs
        end

        # Return all gem build requirements _not_ in the specified gem
        def extra_gem_build_requirements(gem)
          gem_reqs = gem.deps.collect { |d| requirements_for_gem(d.name) }.flatten
          gem_build_requirements - gem_reqs
        end

        # Return contents of spec as string
        #
        # @return [String] string representation of rpm spec
        def to_string
          @metadata[:contents]
        end
      end # class Spec
    end # Component.verify("RPM::Spec")
  end # module RPM
end # module Polisher
