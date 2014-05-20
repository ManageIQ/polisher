# Helpers to check versions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  class VersionChecker
    GEM_TARGET    = :gem
    KOJI_TARGET   = :koji
    FEDORA_TARGET = :fedora
    GIT_TARGET    = :git
    YUM_TARGET    = :yum
    BODHI_TARGET  = :bodhi  # fedora dispatches to bodhi so not enabled by default
    ERRATA_TARGET = :errata # not enabled by default
    ALL_TARGETS   = [GEM_TARGET, KOJI_TARGET, FEDORA_TARGET,
                     GIT_TARGET, YUM_TARGET]

    # Enable the specified target(s) in the list of target to check
    def self.check(*target)
      @check_list ||= []
      target.flatten.each { |t| @check_list << t }
    end

    def self.should_check?(target)
      @check_list ||= ALL_TARGETS
      @check_list.include?(target)
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
      versions = {}

      if should_check?(GEM_TARGET)
        versions.merge! :gem => Gem.local_versions_for(name, &bl)
      end

      if should_check?(FEDORA_TARGET)
        begin
          require 'polisher/fedora'
          versions.merge! :fedora => Fedora.versions_for(name, &bl)
        rescue
          versions.merge! :fedora => unknown_version(:fedora, name, &bl)
        end
      end

      if should_check?(KOJI_TARGET)
        begin
          require 'polisher/koji'
          versions.merge! :koji => Koji.versions_for(name, &bl)
        rescue
          versions.merge! :koji => unknown_version(:koji, name, &bl)
        end
      end

      if should_check?(GIT_TARGET)
        begin
          require 'polisher/git/pkg'
          versions.merge! :git => [Git::Pkg.version_for(name, &bl)]
        rescue
          versions.merge! :git => unknown_version(:git, name, &bl)
        end
      end

      if should_check?(YUM_TARGET)
        begin
          require 'polisher/yum'
          versions.merge! :yum => [Yum.version_for(name, &bl)]
        rescue
          versions.merge! :yum => unknown_version(:yum, name, &bl)
        end
      end

      if should_check?(BODHI_TARGET)
        begin
          require 'polisher/bodhi'
          versions.merge! :bodhi => Bodhi.versions_for(name, &bl)
        rescue
          versions.merge! :bodhi => unknown_version(:bodhi, name, &bl)
        end
      end

      if should_check?(ERRATA_TARGET)
        begin
          require 'polisher/errata'
          versions.merge! :errata => Errata.versions_for(name, &bl)
        rescue
          versions.merge! :errata => unknown_version(:errata, name, &bl)
        end
      end

      versions
    end

    # Return version of package most frequent in all configured targets.
    # Invokes query as normal then counts versions over all targets and
    # returns the max.
    def self.version_for(name)
      versions = self.versions_for(name).values
      versions.inject(Hash.new(0)) { |total, i| total[i] += 1; total }.first
    end

    # Invoke block for specified target w/ an 'unknown' version
    def self.unknown_version(tgt, name)
      yield tgt, name, [:unknown]
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
    def dependency_versions(args = {}, &bl)
      args = {:recursive => true, :dev_deps  => true}.merge(args)
      versions = {}
      self.deps.each do |dep|
        gem = Polisher::Gem.retrieve(dep)
        versions.merge!(gem.versions(args, &bl))
      end
      versions
    end
  end
end
