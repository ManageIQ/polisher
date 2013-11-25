# Polisher Koji Operations
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'xmlrpc/client'
XMLRPC::Config::ENABLE_NIL_PARSER = true
XMLRPC::Config::ENABLE_NIL_CREATE = true

module Polisher
  class Koji
    KOJI_URL = 'koji.fedoraproject.org/kojihub'
    KOJI_TAG = 'f21'

    def self.koji_url(value=nil)
      @koji_url ||= KOJI_URL
      @koji_url   = value unless value.nil?
      @koji_url
    end

    def self.koji_tag(value=nil)
      @koji_tag ||= KOJI_TAG
      @koji_tag   = value unless value.nil?
      @koji_tag
    end

    def self.client
      @client ||= begin
        url = self.koji_url.split('/')
        XMLRPC::Client.new(url[0..-2].join('/'),
                           "/#{url.last}")
      end
    end

    def self.versions_for(name, &bl)
      # koji xmlrpc call
      builds =
        self.client.call('listTagged',
          self.koji_tag, nil, false, nil, false,
          "rubygem-#{name}")
      versions = builds.collect { |b| b['version'] }
      bl.call(:koji, name, versions) unless(bl.nil?) 
      versions
    end
  end
end
