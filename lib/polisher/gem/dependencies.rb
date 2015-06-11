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

      process = []
      deps.each { |dep|
        resolved = nil
        begin
          resolved = Polisher::Gem.matching(dep, matching)
        rescue
        end
        bl.call self, dep, resolved
        process << resolved if recursive && !resolved.nil?
      }

      dev_deps.each { |dep|
        resolved = nil
        begin
          resolved = Polisher::Gem.matching(dep, matching)
        rescue
        end
        bl.call self, dep, resolved
        process << resolved if recursive && !resolved.nil?
      } if retrieve_dev_deps

      process.each { |dep|
        dependencies.merge! dep.dependency_tree args, &bl
      }

      return dependencies
    end
  end # module GemVersions
end # module Polisher
