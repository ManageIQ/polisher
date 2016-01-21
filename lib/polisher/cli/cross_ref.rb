#!/usr/bin/ruby
# Polisher CLI Cross Reference Utils
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def missing_deps
      @missing_deps ||= {}
    end

    def alt_deps
      @alt_deps ||= {}
    end

    def missing_dep?(dep)
      if dep.is_a?(String)
        missing_deps.key?(dep)
      else
        # XXX : need to nullify dep.type for this lookup
        dep.instance_variable_set(:@type, :runtime)
        missing_deps.key?(dep.name) && missing_deps[name].any? { |gdep| gdep == dep }
      end
    end

    def missing_downstream?(dep)
      Polisher::VersionChecker.matching_versions(dep).empty?
    end

    def alternative?(name)
      alt_deps.key?(name)
    end

    def latest_alt(name)
      alt_deps[name].max
    end

    def alt_versions(name)
      Polisher::VersionChecker.known_versions_for(name).values.flatten
    end

    def check_missing_dep(dep)
      dep_already_processed = missing_dep?(dep)      # determine if this requirement was already recorded
      gem_already_processed = missing_dep?(dep.name) # determine if previous requirement was not satified & recorded in deps

      # even if current dep is not missing downstream we need to record all deps for gems with at least one missing dep
      if (!dep_already_processed && missing_downstream?(dep)) || gem_already_processed
        missing_deps[dep.name] ||= []
        missing_deps[dep.name]  << dep unless dep_already_processed
        alt_deps[dep.name]       = alt_versions(dep.name) unless alternative?(dep.name)
      end
    end

    def upstream_versions(name)
      @upstream_versions       ||= {}
      @upstream_versions[name] ||= Polisher::Gem.remote_versions_for(name)
                                                .select { |v| missing_deps[name].all? { |dep| dep.match?(name, v)} }
    end

    def upstream_version?(name)
      !upstream_versions(name).empty?
    end

    def updatable_versions(name)
      latest         = latest_alt(name)
      latest_version = ::Gem::Version.new(latest)
      matching       = upstream_versions(name)
      latest.nil? ? matching : matching.select { |m| ::Gem::Version.new(m) > latest_version }
    end
  end # module CLI
end # module Polisher
