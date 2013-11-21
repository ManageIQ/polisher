# Polisher Gemfile Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

# Supporting both bundler based parsing
# and gemnasuim based parsing
require 'bundler'
require 'gemnasium/parser'

require 'polisher/version_checker'

# Override bundler's gem registration
module Bundler
  class << self
    attr_accessor :bundler_gems

    def init_gems
      Bundler.bundler_gems = []
    end
  end

  class Dsl
    alias :old_gem :gem
    def gem(name, *args)
      Bundler.bundler_gems ||= []
      version = args.first.is_a?(Hash) ? nil : args.first
      Bundler.bundler_gems << [name, version]
      old_gem(name, *args)
    end
  end
end

module Polisher
  class Gemfile
    include VersionedDependencies

    # always nil, for interface compatability
    attr_accessor :version

    attr_accessor :deps
    attr_accessor :dev_deps

    # always empty array, for interface compatability
    attr_accessor :files

    def initialize(args={})
      @version  = nil
      @deps     = args[:deps]
      @dev_deps = args[:dev_deps]
      @files    = []
    end

    def self.parse(path)
      path,g = File.split(path)
      Dir.chdir(path){
        Bundler.init_gems
        Bundler::Definition.build(g, nil, false)
      }
      metadata = {}
      metadata[:deps]     = Bundler.bundler_gems.collect { |n,v| n }
      metadata[:dev_deps] = [] # TODO

      self.new metadata
    end

    def self.gemnasium_parse(path)
      parser = Gemnasium::Parser.gemfile(File.read(path))
      metadata = {:deps => [], :dev_deps => []}
      parser.dependencies.each { |dep|
        metadata[:deps] << dep.name
      }

      self.new metadata
    end
  end # class Gemfile
end # module Polisher
