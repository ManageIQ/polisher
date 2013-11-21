# Polisher Koji Operations
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'xmlrpc/client'
XMLRPC::Config::ENABLE_NIL_PARSER = true
XMLRPC::Config::ENABLE_NIL_CREATE = true

module Polisher
  class Koji
    # TODO parameterize
    KOJI_URL = 'koji.fedoraproject.org/kojihub'
    KOJI_TAG = 'rawhide'

    def self.client
      @client ||= begin
        url = KOJI_URL.split('/')
        XMLRPC::Client.new(url[0..-2].join('/'),
                           "/#{url.last}")
      end
    end

    def self.versions_for(name)
      # koji xmlrpc call
      builds =
        self.client.call('listTagged',
          KOJI_TAG, nil, false, nil, false,
          "rubygem-#{name}")
      builds.collect { |b| b['version'] }
    end
  end
end
