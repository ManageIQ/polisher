# Helpers to check versions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/fedora'
require 'polisher/koji'
require 'polisher/git'
require 'polisher/bodhi'
require 'polisher/yum'

module Polisher
  class VersionChecker
    GEM_TARGET    = :gem
    KOJI_TARGET   = :koji
    FEDORA_TARGET = :fedora
    GIT_TARGET    = :git
    YUM_TARGET    = :yum
    BODHI_TARGET  = :bodhi # fedora dispatches to bodhi to not enabled by default
    ALL_TARGETS   = [GEM_TARGET, KOJI_TARGET, FEDORA_TARGET,
                     GIT_TARGET, YUM_TARGET]

    # Enable the specified target(s) in the list of target to check
    def self.check(target)
      @check_list ||= []
      if target.is_a?(Array)
        target.each { |t| self.check(t) }
        return
      end

      @check_list << target
    end

    # Retrieve all the versions of the specified package using
    # the configured targets.
    #
    # If not specified, all targets are checked
    # @param [String] name name of package to query
    # @param [Callable] bl optional block to invoke with versions retrieved
    # @returns [Hash<target,Array<String>>] returns a hash of target to versions
    # available for specified package
    def self.versions_for(name, &bl)
      @check_list ||= ALL_TARGETS
      versions = {}

      if @check_list.include?(GEM_TARGET)
        versions.merge! :gem => Gem.local_versions_for(name, &bl)
      end

      if @check_list.include?(FEDORA_TARGET)
        versions.merge! :fedora => Fedora.versions_for(name, &bl)
      end

      if @check_list.include?(KOJI_TARGET)
        versions.merge! :koji => Koji.versions_for(name, &bl)
      end

      if @check_list.include?(GIT_TARGET)
        versions.merge! :git => [GitPackage.version_for(name, &bl)]
      end

      if @check_list.include?(YUM_TARGET)
        versions.merge! :yum => [Yum.version_for(name, &bl)]
      end

      if @check_list.include?(BODHI_TARGET)
        versions.merge! :bodhi => Bodhi.versions_for(name, &bl)
      end

      #bodhi_version   = Bodhi.versions_for(name, &bl)
      #errata_version  = Errata.version_for('url?', name, &bl)

      versions
    end

    # Return version of package most frequent in all configured targets.
    # Invokes query as normal then counts versions over all targets and
    # returns the max.
    def self.version_for(name)
      versions = self.versions_for(name).values
      versions.inject(Hasn.new(0)) { |total, i| total[i] += 1; total }.first
    end
  end

  # Helper module to be included in components
  # that contain lists of dependencies which include version information
  module VersionedDependencies

    # Return list of versions of dependencies of component.
    #
    # Requires module define 'deps' method which returns list
    # of gem names representing component dependencies. List
    # will be iterated over, versions will be looked up
    # recursively and returned
    def dependency_versions(&bl)
      versions = {}
      self.deps.each do |dep|
        gem = Polisher::Gem.retrieve(dep)
        versions.merge!(gem.versions(:recursive => true, :dev_deps => true, &bl))
      end
      versions
    end
  end
end
