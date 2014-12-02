# Polisher VersionChecker Errata Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module ErrataVersionChecker
    ERRATA_TARGET = :errata

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def errata_versions(name, &bl)
        require 'polisher/targets/errata'
        logger.debug "versions_for<errata>(#{name})..."
        errata_versions = Errata.versions_for(name, &bl)
        logger.debug errata_versions
        errata_versions
      rescue
        logger.debug 'unknown'
        unknown_version(:errata, name, &bl)
      end
    end # module ClassMethods
  end # module ErrataVersionChecker
end # module Polisher
