# Polisher Git Package (distgit)
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/repo'
require 'polisher/git/pkg/attributes'
require 'polisher/git/pkg/repo'
require 'polisher/git/pkg/versions'
require 'polisher/git/pkg/builder'
require 'polisher/git/pkg/updater'

module Polisher
  module Git
    # Git Based Package
    class Pkg < Repo
      extend Logging

      include PkgAttributes
      include PkgRepo
      include PkgVersions

      include PkgBuilder
      include PkgUpdater

      conf_attr :rpm_prefix,   'rubygem-'
      conf_attr :pkg_cmd,      '/usr/bin/fedpkg'
      conf_attr :md5sum_cmd,   '/usr/bin/md5sum'
      conf_attr :dist_git_url, 'git://pkgs.fedoraproject.org/'
      conf_attr :fetch_tgt,    'master'

      def self.fetch_tgts
        [fetch_tgt].flatten
      end

      def initialize(args = {})
        @name    = args[:name]
        @version = args[:version]
        super(args)
      end
    end # module Pkg
  end # module Git
end # module Polisher
