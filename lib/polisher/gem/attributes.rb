# Polisher Gem Attributes Mixin
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

module Polisher
  module GemAttributes
    attr_accessor :spec
    attr_accessor :name
    attr_accessor :version
    attr_accessor :deps
    attr_accessor :dev_deps

    attr_accessor :path

    def file_name
      "#{name}-#{version}.gem"
    end
  end # module GemAttributes
end # module Polisher
