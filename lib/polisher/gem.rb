# Polisher Gem Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/conf_helpers'
require 'polisher/mixins/vendored_deps'
require 'polisher/gem/attributes'
require 'polisher/gem/dependencies'
require 'polisher/gem/files'
require 'polisher/gem/state'
require 'polisher/gem/versions'
require 'polisher/gem/parser'
require 'polisher/gem/retriever'
require 'polisher/gem/diff'

module Polisher
  class Gem
    include ConfHelpers
    include HasVendoredDeps
    include GemAttributes
    include GemDependencies
    include GemFiles
    include GemState
    include GemVersions
    include GemParser
    include GemRetriever
    include GemDiff

    conf_attr :diff_cmd, :default => '/usr/bin/diff'

    def initialize(args = {})
      @spec     = args[:spec]
      @name     = args[:name]
      @version  = args[:version]
      @path     = args[:path]
      @deps     = args[:deps]     || []
      @dev_deps = args[:dev_deps] || []
    end

    # Returns path to gem, either specified one of downloaded one
    def gem_path
      @path || downloaded_gem_path
    end
  end # class Gem
end # module Polisher
