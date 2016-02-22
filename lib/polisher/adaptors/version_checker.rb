# Helpers to check versions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/logger'
require 'polisher/adaptors/checker_loader'

module Polisher
  class VersionChecker
    extend Logging
    extend CheckerLoader

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
      all_targets.each do |target|
        if should_check?(target)
          target_versions = send target_method(target), name, &bl
          versions.merge! target => target_versions
        end
      end
      versions
    end

    def self.known_versions_for(name, &bl)
      versions = {}
      versions_for(name) do |tgt, _name, target_versions|
        unless target_versions.include?(:unknown)
          bl.call tgt, name, versions unless bl.nil?
          versions.merge! tgt => target_versions
        end
      end
      versions
    end

    # Return version of package most frequent references in each
    # configured target.
    def self.version_for(name)
      Hash[versions_for(name).collect do |k, versions|
        most = versions.group_by { |v| v }.values.max_by(&:size).first
        [k, most]
      end]
    end

    # Return version of package most frequent reference in all
    # configured targets.
    def self.version_of(name)
      version_for(name).values.group_by { |v| v }.values.max_by(&:size).first
    end

    # Invoke block for specified target w/ an 'unknown' version
    def self.unknown_version(tgt, name)
      yield tgt, name, [:unknown] if block_given?
      [:unknown]
    end

    # Return versions matching dependency
    def self.matching_versions(dep)
      versions = known_versions_for(dep.name).values.flatten.uniq.compact
      versions.select { |v| dep.match? dep.name, v }
    end
  end
end
