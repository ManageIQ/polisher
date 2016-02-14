# Polisher Gem Dependencies Mixin
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/adaptors/version_checker'

module Polisher
  module GemDependencies
    # Retrieve map of gems to dependencies (optionally recursively)
    def dependency_tree(args = {}, &bl)
      local_args        = Hash[args]
      recursive         = local_args[:recursive]
      retrieve_dev_deps = local_args[:dev_deps]
      matching          = local_args[:matching]
      dependencies      = local_args[:dependencies] || {}
      return dependencies if dependencies.key?(name) && dependencies[name].key?(version)

      dependencies[name]          ||= {}
      dependencies[name][version]   = deps + dev_deps
      args[:dependencies]           = dependencies

      resolved_deps = resolve_tree_deps(args.merge({:deps => deps}),     &bl)
      resolved_dev  = retrieve_dev_deps ? resolve_tree_deps(args.merge({:deps => dev_deps}), &bl) : []

      (resolved_deps + resolved_dev).each { |dep|
        dependencies.merge! dep.dependency_tree(args, &bl)
        args[:dependencies] = dependencies
      } if recursive

      return dependencies
    end

    private

    def resolve_tree_deps(args = {}, &bl)
      deps = args[:deps]
      deps.collect { |dep|
        resolve_tree_dep args.merge({:dep => dep}), &bl
      }
    end

    def resolve_tree_dep(args = {}, &bl)
      dep          = args[:dep]
      matching     = args[:matching]

      resolved = nil
      begin
        resolved = Polisher::Gem.matching(dep, matching)
      rescue
      end
      bl.call self, dep, resolved

      return resolved unless resolved.nil?

      begin
        Polisher::Gem.latest_matching(dep)
      rescue
        Polisher::Gem.retrieve_latest(dep.name)
      end
    end
  end # module GemVersions
end # module Polisher
