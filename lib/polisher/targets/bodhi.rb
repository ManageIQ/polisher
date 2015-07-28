# Polisher Bodhi Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

# XXX issue w/ retreiving packages from pkgwat causing sporadic issues:
# https://github.com/fedora-infra/fedora-packages/issues/55

# another issue seems to result in url's sometimes
# html anchors being returned in version field, use
# nokogiri to pull this out
require 'nokogiri'

module Polisher
  # fedora pkgwat provides a frontend to bodhi
  class Bodhi
    def self.versions_for(name, &bl)
      require 'pkgwat'
      versions = Pkgwat.get_updates("rubygem-#{name}", 'all', 'all')
                       .select  { |update| update['stable_version']  != 'None' }
                       .collect { |update| update['stable_version'] }
      versions = sanitize(versions)
      bl.call(:bodhi, name, versions) unless bl.nil?
      versions
    end

    private

    def self.sanitize(versions)
      versions.collect { |v|
        is_url?(v) ? url2version(v) : v
      }
    end

    def self.is_url?(version)
      !Nokogiri::HTML(version).css('a').empty?
    end

    def self.url2version(version)
      Nokogiri::HTML(version).text
    end
  end
end
