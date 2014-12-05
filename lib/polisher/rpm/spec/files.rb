# RPM Spec Files Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module RPM
    module SpecFiles
      # Return list of all files in the spec
      def files
        pkg_files.values.flatten
      end
    end # module SpecFiles
  end # module RPM
end # module Polisher
