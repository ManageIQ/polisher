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

    # Return version of package most frequent in all configured targets.
    # Invokes query as normal then counts versions over all targets and
    # returns the max.
    def self.version_for(name)
      versions = versions_for(name).values
      versions.inject(Hash.new(0)) do |total, i|
        total[i] += 1
        total
      end.first
    end

    # Invoke block for specified target w/ an 'unknown' version
    def self.unknown_version(tgt, name)
      yield tgt, name, [:unknown]
    end

    # Return versions matching dependency
    def self.matching_versions(dep)
      versions = versions_for(dep.name).values.flatten.uniq.compact
      versions.select { |v| dep.match? dep.name, v }
    end
  end
end
