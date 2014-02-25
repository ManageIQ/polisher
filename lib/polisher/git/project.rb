# Polisher Git Based Project Representation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/vendor'
require 'polisher/git/repo'

module Polisher
  module Git
    # Git based project representation
    class Project < Repo
      include HasVendoredDeps

      # Override vendored to ensure repo is
      # cloned before retrieving modules
      def vendored
        clone unless cloned?
        super
      end
    end # class Project
  end # module Git
end # module Polisher
