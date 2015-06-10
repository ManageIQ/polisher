# Polisher Gem Dependencies Mixin
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/adaptors/version_checker'

module Polisher
  module GemDependencies
    def dependency_tree(args = {}, &bl)
      local_args        = Hash[args]
      recursive         = local_args[:recursive]
      retrieve_dev_deps = local_args[:dev_deps]
      matching          = local_args[:matching]
      dependencies      = local_args[:dependencies] || {}
      dep_key           = [name, version]
      return dependencies if dependencies.key?(dep_key)

      dependencies.merge! dep_key => deps

      deps.each { |d|
        bl.call self, d
        gem_dep = Polisher::Gem.matching(d, matching)
        dependencies.merge gem_dep.dependency_tree args, &bl if recursive
      }

      dev_deps.each { |d|
        bl.call self, d
        gem_dep = Polisher::Gem.matching(d, matching)
        dependencies.merge gem_dep.dependency_tree args, &bl if recursive
      } if retrieve_dev_deps

      return dependencies
    end
  end # module GemVersions
end # module Polisher
