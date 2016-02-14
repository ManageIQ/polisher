# Polisher VersionChecker Yum Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module YumVersionChecker
    def self.default?
      @default ||= true
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def yum_versions(name, &bl)
        require 'polisher/targets/yum'
        logger.debug "versions_for<yum>(#{name})..."
        yum_versions = [Yum.version_for(name, &bl)].compact
        logger.debug yum_versions
        yum_versions
      rescue
        logger.debug 'unknown'
        unknown_version(:yum, name, &bl)
      end
    end # module ClassMethods
  end # module YumVersionChecker
end # module Polisher
