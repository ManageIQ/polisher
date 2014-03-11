# Polisher Koji Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'xmlrpc/client'
require 'active_support/core_ext/kernel/reporting'
silence_warnings do
  XMLRPC::Config::ENABLE_NIL_PARSER = true
  XMLRPC::Config::ENABLE_NIL_CREATE = true
end

require 'polisher/core'

module Polisher
  class Koji
    extend ConfHelpers

    # TODO Koji#build (on class or instance?)

    # TODO Koji#diff(tag1, tag2)

    conf_attr :koji_url, 'koji.fedoraproject.org/kojihub'
    conf_attr :koji_tag, 'f21'

    # Retrieve shared instance of xmlrpc client to use
    def self.client
      @client ||= begin
        url = koji_url.split('/')
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
          koji_tag, nil, false, nil, false,
          "rubygem-#{name}")
      versions = builds.collect { |b| b['version'] }
      bl.call(:koji, name, versions) unless(bl.nil?) 
      versions
    end
  end
end
