# Polisher Gem Parser Mixin
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'rubygems/installer'

module Polisher
  module GemParser
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Return new instance of Gem from Gemspec
      def from_gemspec(gemspec)
        gemspec  =
          ::Gem::Specification.load(gemspec) if !gemspec.is_a?(::Gem::Specification) &&
                                                 File.exist?(gemspec)

        metadata            = {}
        metadata[:spec]     = gemspec
        metadata[:name]     = gemspec.name
        metadata[:version]  = gemspec.version.to_s
        metadata[:deps]     = gemspec.dependencies
                                     .select  { |dep| dep.type == :runtime }
                                     .collect { |dep| dep }
        metadata[:dev_deps] = gemspec.dependencies
                                     .select  { |dep| dep.type == :development }
                                     .collect { |dep| dep }

        new metadata
      end

      # Return new instance of Gem from JSON Specification
      def from_json(json)
        specj     = JSON.parse(json)
        metadata           = {}
        metadata[:spec]    = specj
        metadata[:name]    = specj['name']
        metadata[:version] = specj['version']

        metadata[:deps] =
          specj['dependencies']['runtime'].collect do |d|
            ::Gem::Dependency.new d['name'], *d['requirements'].split(',')
          end

        metadata[:dev_deps] =
          specj['dependencies']['development'].collect do |d|
            ::Gem::Dependency.new d['name'], d['requirements'].split(',')
          end

        new metadata
      end

      # Return new instance of Gem from rubygem
      def from_gem(gem_path)
        gem = parse :gemspec => ::Gem::Package.new(gem_path).spec
        gem.path = gem_path
        gem
      end

      # Parse the specified gemspec & return new Gem instance from metadata
      #
      # @param [String,Hash] args contents of actual gemspec of option hash
      # specifying location of gemspec to parse
      # @option args [String] :gemspec path to gemspec to load / parse
      # @return [Polisher::Gem] gem instantiated from gemspec metadata
      def parse(args = {})
        if args.is_a?(String)
          return from_json args

        elsif args.key?(:gemspec)
          return from_gemspec args[:gemspec]

        elsif args.key?(:gem)
          return from_gem args[:gem]

        end

        new
      end
    end # module ClassMethods
  end # module GemParser
end # module Polisher
