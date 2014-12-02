# Polisher VersionChecker Git Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module GitVersionChecker
    def self.default?
      @default ||= true
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def git_versions(name, &bl)
        require 'polisher/git/pkg'
        logger.debug "versions_for<git>(#{name})..."
        git_versions = Git::Pkg.versions_for(name, &bl)
        logger.debug git_versions
        git_versions
      rescue
        logger.debug 'unknown'
        unknown_version(:git, name, &bl)
      end
    end # module ClassMethods
  end # module GitVersionChecker
end # module Polisher
