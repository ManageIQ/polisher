# Helpers to check versions
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/fedora'
require 'polisher/koji'
require 'polisher/git'
require 'polisher/bodhi'
require 'polisher/yum'

module Polisher
  class VersionChecker
    def self.versions_for(name, &bl)
      gem_versions    = Gem.local_versions_for(name, &bl)
      fedora_versions = Fedora.versions_for(name, &bl)
      koji_versions   = Koji.versions_for(name, &bl)
      git_version     = GitPackage.version_for(name, &bl)
      yum_version     = Yum.version_for(name, &bl)
      #bodhi_version   = Bodhi.versions_for(name, &bl)
      #errata_version  = Errata.version_for('url?', name, &bl)

      {:gem    => gem_versions,
       :koji   => koji_versions,
       :fedora => fedora_versions,
       :git    => [git_version],
       :yum    => [yum_version]}
    end

    def self.version_for(name)
      versions = self.versions_for(name).values
      versions.inject(Hasn.new(0)) { |total, i| total[i] += 1; total }.first
    end
  end

  module VersionedDependencies
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
