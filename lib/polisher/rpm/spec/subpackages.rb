# RPM Spec Subpackages Module
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module RPM
    module SpecSubpackages
      # Return subpkg containing the specified file
      def subpkg_containing(file)
        pkg_files.each do |pkg, spec_files|
          return pkg if spec_files.include?(file)
        end
        nil
      end

      # Return boolean indicating if spec has a -doc subpkg
      def has_doc_subpkg?
        @has_doc_subpkg ||= contents.index Spec::SPEC_DOC_SUBPACKAGE_MATCHER
      end
    end # module SpecSubpackages
  end  # module RPM
end # module Polisher
