# Polisher RPM Spec Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require "active_support/core_ext/hash/except"

require 'polisher/rpm/spec/requirements'
require 'polisher/rpm/spec/files'
require 'polisher/rpm/spec/subpackages'
require 'polisher/rpm/spec/check'

require 'polisher/rpm/spec/updater'
require 'polisher/rpm/spec/parser'
require 'polisher/rpm/spec/comparison'

require 'polisher/rpm/spec/gem_files'
require 'polisher/rpm/spec/gem_reference'
require 'polisher/rpm/spec/gem_requirements'

module Polisher
  module RPM
    class Spec
      include SpecRequirements
      include SpecFiles
      include SpecSubpackages
      include SpecCheck

      include SpecUpdater
      include SpecParser
      include SpecComparison

      # TODO: make these mixins optional depending on if rpm corresponds to gem
      include SpecGemFiles
      include SpecGemReference
      include SpecGemRequirements

      AUTHOR = "#{ENV['USER']} <#{ENV['USER']}@localhost.localdomain>"

      # metadata keys parsed
      # @see [Polisher::RPM::SpecParser::ClassMethods#parse]
      METADATA_IDS = [:contents, :name, :gem_name, :full_name, :version, :release,
                      :requires, :build_requires, :has_check, :changelog,
                      :pkg_excludes, :pkg_files, :changelog_entries]

      COMMENT_MATCHER             = /^\s*#.*/
      SPEC_NAME_MATCHER           = /^Name:\s*(.*)$/
      SPEC_PREFIXED_NAME_MATCHER  = /^Name:\s*#{package_prefix}-(.*)$/
      SPEC_VERSION_MATCHER        = /^Version:\s*(.*)$/
      SPEC_RELEASE_MATCHER        = /^Release:\s*(.*)$/
      SPEC_REQUIRES_MATCHER       = /^Requires:\s*(.*)$/
      SPEC_BUILD_REQUIRES_MATCHER = /^BuildRequires:\s*(.*)$/
      SPEC_GEM_REQ_MATCHER        = /^.*\s*#{requirement_prefix}\((.*)\)(\s*(.*))?$/
      SPEC_SUBPACKAGE_MATCHER     = /^%package\s(.*)$/
      SPEC_DOC_SUBPACKAGE_MATCHER = /^%package\sdoc$/
      SPEC_CHANGELOG_MATCHER      = /^%changelog$/
      SPEC_FILES_MATCHER          = /^%files$/
      SPEC_SUBPKG_FILES_MATCHER   = /^%files\s*(.*)$/
      SPEC_EXCLUDED_FILE_MATCHER  = /^%exclude\s+(.*)$/
      SPEC_PREP_MATCHER           = /^%prep$/
      SPEC_CHECK_MATCHER          = /^%check$/
      SPEC_DESCRIPTION_MATCHER    = /^%description$/

      FILE_MACRO_MATCHERS         =
        [/^%doc\s/,     /^%config\s/,  /^%attr\s/,
         /^%verify\s/,  /^%docdir.*/,  /^%dir\s/, /^%defattr.*/,
         /^%{gem_instdir}\/+/, /^%{gem_cache}/, /^%{gem_spec}/, /^%{gem_docdir}/]

      FILE_MACRO_REPLACEMENTS     =
        {"%{_bindir}"    => 'bin', "%{gem_libdir}" => 'lib'}

      attr_accessor :metadata
      attr_accessor :macros

      def initialize(args={})
        @metadata = metadata_args args
        @macros   = macro_args    args
      end

      def metadata_args(args)
        specified = args[:metadata] || args.except(:macros) || {}
        self.class.default_metadata.merge(specified)
      end

      def macro_args(args)
        args[:macros] || {}
      end

      # Dispatch all missing methods to lookup calls in rpm spec metadata
      def method_missing(method, *args, &block)
        # proxy to metadata
        return @metadata[method] if @metadata.key?(method)

        # return nil if metadata value not set
        return nil if METADATA_IDS.include?(method)

        # set value if invoking metadata setter
        id = method[0...-1].intern if method[-1] == '='
        metadata_setter = METADATA_IDS.include?(id) && args.length == 1
        return @metadata[id] = args.first if metadata_setter

        # dispatch to default behaviour
        super(method, *args, &block)
      end

      def macro_for(label)
        @macros[label]
      end

      # Return contents of spec as string
      #
      # @return [String] string representation of rpm spec
      def to_string
        contents
      end

      # Return length of contents
      def length
        contents.length
      end
    end # class Spec
  end # module RPM
end # module Polisher
