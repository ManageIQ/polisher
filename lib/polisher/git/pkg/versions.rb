# Polisher Git Package Versions Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/logger'

module Polisher
  module Git
    module PkgVersions
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Retrieve list of the versions of the specified package in git
        #
        # @param [String] name name of package to lookup
        # @param [Callable] bl optional block to invoke with version retrieved
        # @return [Array<String>] versions retrieved, or empty array if none found
        def versions_for(name, &bl)
          gitpkg = new :name => name
          gitpkg.url = "#{dist_git_url}#{gitpkg.rpm_name}.git"
          versions = []
          fetch_tgts.each do |tgt|
            begin
              gitpkg.fetch tgt
              versions << gitpkg.spec.version
            rescue => e
              logger.warn "error retrieving #{name} from #{gitpkg.url}/#{tgt}(distgit): #{e}"
            end
          end
          bl.call(:git, name, versions) unless bl.nil?
          versions
        end
      end # module ClassMethods
    end # module PkgVersions
  end # module Git
end # module Polisher
