# Polisher VersionChecker Bodhi Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module BodhiVersionChecker
    BODHI_TARGET  = :bodhi  # fedora dispatches to bodhi so not enabled by default

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def bodhi_versions(name, &bl)
        require 'polisher/targets/bodhi'
        logger.debug "versions_for<bodhi>(#{name})..."
        bodhi_versions = Bodhi.versions_for(name, &bl)
        logger.debug bodhi_versions
        bodhi_versions
      rescue
        logger.debug 'unknown'
        unknown_version(:bodhi, name, &bl)
      end
    end # module ClassMethods
  end # module BodhiVersionChecker
end # module Polisher
