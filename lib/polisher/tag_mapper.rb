# Polisher Tag Mapper, simple mechanism to associate
# tags with each other
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/core'

module Polisher
  class TagMapper
    extend ConfHelpers

    def self.method_missing(id, *args, &bl)
      set(id.to_s, args.first)
    end

    def self.set(tag, value)
      @tags ||= {}
      @tags[tag] = value
    end

    def self.map(tag)
      @tags[tag]
    end
  end # class TagMapper
end # module Polisher
