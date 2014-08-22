# VersionedDependencies Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  # Mixin included in components that contain lists of dependencies
  # which include version information
  #
  # Requires module define 'deps' method which returns list
  # of gem names representing component dependencies. List
  # will be iterated over, versions will be looked up
  # recursively and returned
  module VersionedDependencies
    # Return specified dependency
    def dependency_for(name)
      deps.detect { |dep| dep.name == name }
    end

    # Return list of versions of dependencies of component.
    def dependency_versions(args = {}, &bl)
      args = {:recursive => true, :dev_deps  => true}.merge(args)
      versions = {}
      deps.each do |dep|
        gem = Polisher::Gem.retrieve(dep.name)
        versions.merge!(gem.versions(args, &bl))
      end
      versions
    end

    # Return missing dependencies
    def missing_dependencies
      missing = []
      dependency_versions(:recursive => false).each do |pkg, target_versions|
        found = false
        target_versions.each do |_target, versions|
          dependency = dependency_for(pkg)
          found = versions.any? { |version| dependency.match?(pkg, version) }
        end
        missing << pkg unless found
      end
      missing
    end

    # Return bool indicating if all dependencies are satisfied
    def dependencies_satisfied?
      missing_dependencies.empty?
    end

    # Return list of states which gem dependencies are in
    def dependency_states
      states = {}
      deps.each do |dep|
        gem = Polisher::Gem.new :name => dep.name
        states.merge! dep.name => gem.state(:check => dep)
      end
      states
    end
  end
end
