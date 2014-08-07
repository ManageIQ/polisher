# Polisher Vendor Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  class Vendor
  end

  module HasVendoredDeps
    # Return list of file paths marked as vendored
    #
    # Scope which this module is being mixed into
    # must defined 'file_paths'
    def vendored_file_paths
      file_paths.select { |f| f.include?('vendor/') }
    end

    # Return list of vendered gems in file list
    def vendored
      vendored_file_paths.inject({}) do |v, fp|
        vendored_file = fp.split('/')
        vendor_index  = vendored_file.index('vendor')

        # only process vendor'd dirs:
        next v if vendor_index + 2 == vendored_file.size

        vname = vendored_file[vendor_index + 1]
        vversion = nil
        # TODO: set vversion from version.rb:
        # vf.last.downcase == 'version.rb'
        v[vname] = vversion
        v
      end
    end
  end
end
