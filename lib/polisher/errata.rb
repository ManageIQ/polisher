# Polisher Errata Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'json'
require 'curb'

module Polisher
  class Errata
    # Initialize/return singleton curl handle to
    # query errata and set url
    def self.client(url)
      @curl ||= begin
        c = Curl::Easy.new
        c.ssl_verify_peer = false
        c.ssl_verify_host = false
        c.http_auth_types = :negotiate
        c.userpwd = ':'
        c.get
      end

      @curl.url = url
      @curl
    end

    def self.versions_for(advisory_url, name, &bl)
      result = self.client("#{advisory_url}/builds").get
      versions =
        JSON.parse(result.body_str).collect { |tag, builds|
          ErrataBuild.builds_matching(builds, name)
        }.flatten

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
      pkg =~ /^rubygem-#{name}-([^-]*)-.*$/
    end

    def self.build_version(build, name)
      pkg,meta = *build.flatten
      pkg.split('-')[2]
    end
  end
end
