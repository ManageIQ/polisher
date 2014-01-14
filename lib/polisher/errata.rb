# Polisher Errata Operations
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'json'
require 'curb'

module Polisher
  class Errata
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
      url    = "#{advisory_url}/builds"
      result = self.client(url).get
      json   = JSON.parse result.body_str
      versions =
        json.collect { |tag, builds|
          builds.collect { |build|
            pkg,meta = *build.flatten
            if pkg =~ /^rubygem-#{name}-([^-]*)-.*$/
              $1
            else
              nil
            end
          }
        }.flatten.compact
      bl.call(:errata, name, versions) unless(bl.nil?) 
      versions
    end
  end
end
