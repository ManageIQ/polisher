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

    # Get/Set the koji url
    def self.koji_url(value=nil)
      @koji_url ||= KOJI_URL
      @koji_url   = value unless value.nil?
      @koji_url
    end

    # Get/Set the koji tag to use
    def self.koji_tag(value=nil)
      @koji_tag ||= KOJI_TAG
      @koji_tag   = value unless value.nil?
      @koji_tag
    end

    # Retrieve shared instance of xmlrpc client to use
    def self.client
      @client ||= begin
        url = self.koji_url.split('/')
        XMLRPC::Client.new(url[0..-2].join('/'),
                           "/#{url.last}")
      end
    end

    # Return bool indiciating if koji has a build exactly
    # matching the specified version
    def self.has_build?(name, version)
      versions = self.versions_for name
      versions.include?(version)
    end

    # Return bool indicating if koji has a build which
    # satisfies the specified ruby dependency
    def self.has_build_satisfying?(name, version)
      dep = ::Gem::Dependency.new name, version
      self.versions_for(name).any? { |v|
        dep.match?(name, v)
      }
    end

    # Retrieve list of the version of the specified package in koji
    #
    # @param [String] name name of package to lookup
    # @param [Callable] bl optional block to invoke with versions retrieved
    # @return [String] versions retrieved, or nil if none found
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
