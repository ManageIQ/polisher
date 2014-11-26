# Helpers to check versions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/logger'

require 'polisher/adaptors/version_checker/gem'
require 'polisher/adaptors/version_checker/fedora'
require 'polisher/adaptors/version_checker/koji'
require 'polisher/adaptors/version_checker/git'
require 'polisher/adaptors/version_checker/yum'
require 'polisher/adaptors/version_checker/bodhi'
require 'polisher/adaptors/version_checker/errata'

module Polisher
  class VersionChecker
    extend Logging

    include GemVersionChecker
    include FedoraVersionChecker
    include KojiVersionChecker
    include GitVersionChecker
    include YumVersionChecker
    include BodhiVersionChecker
    include ErrataVersionChecker # not enabled by default

    ALL_TARGETS   = [GEM_TARGET, KOJI_TARGET, FEDORA_TARGET, GIT_TARGET, YUM_TARGET]

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

      versions.merge! :gem    => gem_versions(name, &bl)    if should_check?(GEM_TARGET)
      versions.merge! :fedora => fedora_versions(name, &bl) if should_check?(FEDORA_TARGET)
      versions.merge! :koji   => koji_versions(name, &bl)   if should_check?(KOJI_TARGET)
      versions.merge! :git    => git_versions(name, &bl)    if should_check?(GIT_VERSIONS)
      versions.merge! :yum    => yum_versions(name, &bl)    if should_check?(YUM_VERSIONS)
      versions.merge! :bodhi  => bodhi_versions(name, &bl)  if should_check?(BODHI_VERSIONS)
      versions.merge! :errata => errata_versions(name, &bl) if should_check?(ERRATA_VERSIONS)

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
  end
end
