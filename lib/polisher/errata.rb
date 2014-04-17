# Polisher Errata Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'json'
require 'curb'

require 'polisher/core'

module Polisher
  class Errata
    extend ConfHelpers

    conf_attr :advisory_url, ''
    conf_attr :package_prefix, 'rubygem-'

    # Initialize/return singleton curl handle to query errata
    def self.client
      @curl ||= begin
        curl = Curl::Easy.new
        curl.ssl_verify_peer = false
        curl.ssl_verify_host = false
        curl.http_auth_types = :negotiate
        curl.userpwd = ':'
        curl
      end
    end

    def self.clear!
      @cached_url = nil
      @cached_builds = nil
      self
    end

    def self.builds
      @cached_url    ||= advisory_url
      @cached_builds ||= nil

      if @cached_url != advisory_url || @cached_builds.nil?
        client.url     = "#{advisory_url}/builds"
        @cached_builds = client.get
        @cached_builds = JSON.parse(client.body_str)
      end

      @cached_builds
    end

    def self.versions_for(name, &bl)
      versions = builds.collect do |tag, builds|
        ErrataBuild.builds_matching(builds, name)
      end.flatten
      bl.call(:errata, name, versions) unless(bl.nil?) 
      versions
    end
  end

  class ErrataBuild
    def self.builds_matching(builds, name)
      builds.collect { |build|
        self.build_matches?(build, name) ? self.build_version(build, name) : nil
      }.compact
    end

    def self.build_matches?(build, name)
      pkg,meta = *build.flatten
      pkg =~ /^#{Errata.package_prefix}#{name}-([^-]*)-.*$/
    end

    def self.build_version(build, name)
      pkg,meta = *build.flatten
      pkg.gsub(Errata.package_prefix, '').split('-')[1]
    end
  end
end
