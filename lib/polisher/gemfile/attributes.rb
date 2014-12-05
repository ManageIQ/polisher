# Polisher Gemfile Attributes Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module GemfileAttributes
    # always nil, for interface compatability
    attr_accessor :version

    attr_accessor :deps
    attr_accessor :dev_deps

    # always empty array, for interface compatability
    attr_accessor :file_paths

    attr_accessor :definition
  end # module GemfileAttributes
end # module Polisher
