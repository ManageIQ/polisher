# Polisher Koji Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/conf_helpers'

require 'polisher/targets/koji/rpc'
require 'polisher/targets/koji/versions'
require 'polisher/targets/koji/builder'
require 'polisher/targets/koji/diff'

module Polisher
  class Koji
    include ConfHelpers

    include KojiRpc
    include KojiVersions
    include KojiBuilder
    include KojiDiff

    conf_attr :koji_url, 'koji.fedoraproject.org/kojihub'
    conf_attr :koji_tag, 'f21'
    conf_attr :package_prefix, 'rubygem-'

    # XXX don't like having to shell out to koji but quickest
    # way to get an authenticated session so as to launch builds
    conf_attr :build_cmd, '/usr/bin/koji'
    conf_attr :build_tgt,    'rawhide'

    def self.koji_tags
      [koji_tag].flatten
    end

    def self.package_prefixes
      [package_prefix].flatten
    end
  end # class Koji
end # module Polisher
