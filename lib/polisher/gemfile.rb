# Polisher Gemfile Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'bundler'

require 'polisher/git'
require 'polisher/gem'
require 'polisher/version_checker'

module Polisher
  class Gemfile
    include VersionedDependencies

    # always nil, for interface compatability
    attr_accessor :version

    attr_accessor :deps
    attr_accessor :dev_deps

    # always empty array, for interface compatability
    attr_accessor :file_paths

    def initialize(args={})
      @version  = nil
      @deps     = args[:deps]
      @dev_deps = args[:dev_deps]
      @definition = args[:definition]
      @file_paths = []
    end

    # Parse the specified gemfile & return new Gemfile instance from metadata
    # 
    # @param [String] path to gemfile to parse
    # @return [Polisher::Gemfile] gemfile instantiated from parsed metadata
    def self.parse(path, args={})
      groups = args[:groups]

      definition = nil
      path,g = File.split(path)
      Dir.chdir(path){
        begin
          definition = Bundler::Definition.build(g, nil, false)
        rescue Bundler::GemfileNotFound
          raise ArgumentError, "invalid gemfile: #{path}"
        end
      }

      metadata = {}
      metadata[:deps] =
        definition.dependencies.select { |d|
           groups.nil? || groups.empty? ||                  # groups not specified
           groups.any? { |g| d.groups.include?(g.intern) }  # dep in any group
        }.collect { |d| d.name }

      metadata[:dev_deps] = [] # TODO
      metadata[:definition] = definition

      self.new metadata
    end

    # Simply alias for all dependencies in Gemfile
    def vendored
      deps + dev_deps
    end

    # Retrieve gems which differ from
    # rubygems.org/other upstream sources
    def patched
      vendored.collect do |dep|
        bundler_dep = @definition ?
                      @definition.dependencies.find { |d| d.name == dep } : nil

        # TODO right now just handling git based alternate sources,
        # should be able to handle other types bundler supports
        # (path and alternate rubygems src)
        next unless bundler_dep && bundler_dep.source.is_a?(Bundler::Source::Git)
        src = bundler_dep.source

        # retrieve gem
        gem = src.version ?
              Polisher::Gem.new(:name => dep, :version => src.version) :
              Polisher::Gem.retrieve(dep)

        # retrieve dep
        git = Polisher::Git::Repo.new :url => src.uri
        git.clone unless git.cloned?
        git.checkout src.ref if src.ref

        # diff gem against git
        gem.diff(git.path)
      end.compact!
    end
  end # class Gemfile
end # module Polisher
