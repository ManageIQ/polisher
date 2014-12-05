# Polisher VersionChecker Fedora Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module FedoraVersionChecker
    FEDORA_TARGET = :fedora

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def fedora_versions(name, &bl)
        require 'polisher/targets/fedora'
        logger.debug "versions_for<fedora>(#{name})..."
        fedora_versions = Fedora.versions_for(name, &bl)
        logger.debug fedora_versions
        fedora_versions
      rescue
        logger.debug 'unknown'
        unknown_version(:fedora, name, &bl)
      end
    end # module ClassMethods
  end # module FedoraVersionChecker
end # module Polisher
