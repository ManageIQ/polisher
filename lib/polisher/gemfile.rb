# Polisher Gemfile
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/mixins/versioned_dependencies'
require 'polisher/gemfile/attributes'
require 'polisher/gemfile/parser'
require 'polisher/gemfile/deps'

module Polisher
  class Gemfile
    include VersionedDependencies
    include GemfileAttributes
    include GemfileDeps
    include GemfileParser

    def initialize(args = {})
      @version    = nil
      @deps       = args[:deps]
      @dev_deps   = args[:dev_deps]
      @definition = args[:definition]
      @file_paths = []
    end
  end # class Gemfile
end # module Polisher
