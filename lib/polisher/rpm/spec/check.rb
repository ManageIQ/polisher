# RPM Spec Check Module
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module RPM
    module SpecCheck
      def has_check?
        !!has_check
      end
    end # module SpecCheck
  end  # module RPM
end # module Polisher
