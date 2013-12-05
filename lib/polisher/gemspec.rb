# Polisher Gemspec Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'gemnasium/parser'

require 'polisher/version_checker'

module Polisher
  class Gemspec
    include VersionedDependencies

    attr_accessor :deps

    def initialize(args={})
      @deps     = args[:deps]
    end

    # Parse the specified gemspec & return new Gemspec instance from metadata
    #
    # @param [String] path to gemspec to parse
    # @return [Polisher::Gemspec] gemspec instantiated from parsed metadata
    def self.parse(path)
      parser = Gemnasium::Parser.gemspec(File.read(path))
      metadata = {:deps => [], :dev_deps => []}
      parser.dependencies.each { |dep|
        metadata[:deps] << dep.name
      }

      self.new metadata
    end
  end
end
