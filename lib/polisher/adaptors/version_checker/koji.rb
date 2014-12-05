# Polisher VersionChecker Koji Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module KojiVersionChecker
    KOJI_TARGET   = :koji

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def koji_versions(name, &bl)
        require 'polisher/targets/koji'
        logger.debug "versions_for<koji>(#{name})..."
        koji_versions = Koji.versions_for(name, &bl)
        logger.debug koji_versions
        koji_versions
      rescue
        logger.debug 'unknown'
        unknown_version(:koji, name, &bl)
      end
    end # module ClassMethods
  end # module KojiVersionChecker
end # module Polisher
