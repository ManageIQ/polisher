# Polisher Koji RPC Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'xmlrpc/client'
require 'active_support'
require 'active_support/core_ext/kernel/reporting'

silence_warnings do
  XMLRPC::Config::ENABLE_NIL_PARSER = true
  XMLRPC::Config::ENABLE_NIL_CREATE = true
end

module Polisher
  module KojiRpc
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Retrieve shared instance of xmlrpc client to use
      def client
        @client ||= begin
          url = koji_url.split('/')
          XMLRPC::Client.new(url[0..-2].join('/'),
                             "/#{url.last}")
        end
      end

      # Return list of tags for which a package exists
      #
      # @param [String] name of package to lookup
      # @return [Hash<String,String>] hash of tag names to package versions for tags
      # which package was found in
      def tagged_in(name)
        #                               tagid  userid         pkgid  prefix inherit with_dups
        pkgs = client.call('listPackages', nil, nil, "rubygem-#{name}", nil, false, true)
        pkgs.collect { |pkg| pkg['tag_name'] }
      end
    end # module ClassMethods
  end # module KojiRpc
end # module Polisher
