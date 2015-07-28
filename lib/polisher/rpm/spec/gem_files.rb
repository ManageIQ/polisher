# RPM Spec Gem Files Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/core_ext'

module Polisher
  module RPM
    module SpecGemFiles
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Helper to return bool indicating if specified gem file is satisfied
        # by specified spec file.
        #
        # Spec file satisfies gem file if they are the same or the spec file
        # corresponds to the the directory in which the gem file resides.
        def file_satisfies?(spec_file, gem_file)
          # If spec file for which gemfile.gsub(/^specfile/)
          # is different than the gemfile the spec contains the gemfile
          #
          # TODO: need to incorporate regex matching into this
          gem_file.gsub(/^#{spec_file.unrpmize}/, '') != gem_file
        end
      end # module ClassMethods

      # Return bool indicating if spec is missing specified gemfile.
      def missing_gem_file?(gem_file)
        files.none? { |spec_file| self.class.file_satisfies?(spec_file, gem_file) }
      end

      # Return list of gem files for which we have no corresponding spec files
      def missing_files_for(gem)
        # we check for files in the gem for which there are no spec files
        # corresponding to gem file or directory which it resides in
        gem.file_paths.select { |gem_file| missing_gem_file?(gem_file) }
      end

      # Return list of files in upstream gem which have not been included
      def excluded_files
        # TODO: also append files marked as %{exclude} (or handle elsewhere?)
        missing_files_for(upstream_gem)
      end

      # Return boolean indicating if the specified file is on excluded list
      def excludes_file?(file)
        excluded_files.include?(file)
      end

      # Return extra package file _not_ in the specified gem
      def extra_gem_files(gem = nil)
        gem ||= upstream_gem
        pkg_extra = {}
        pkg_files.each do |pkg, files|
          extra = files.select { |spec_file| !gem.has_file_satisfied_by?(spec_file) }
          pkg_extra[pkg] = extra unless extra.empty?
        end
        pkg_extra
      end
    end # module SpecGemFiles
  end # module RPM
end # module Polisher
