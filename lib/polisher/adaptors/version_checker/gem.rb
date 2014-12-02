# Polisher VersionChecker Gem Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  module GemVersionChecker
    def self.default?
      @default ||= true
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def gem_versions(name, &bl)
        logger.debug "versions_for<gem>(#{name})..."
        gem_versions = Gem.local_versions_for(name, &bl)
        logger.debug gem_versions
        gem_versions
      end
    end # module ClassMethods
  end # module GemVersionChecker
end # module Polisher
