# Polisher RHN Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.
require 'polisher/component'

module Polisher
  Component.verify("RHN", "pkgwat") do
    class RHN
      def self.version_for(name)
        # TODO
      end
    end
  end
end
