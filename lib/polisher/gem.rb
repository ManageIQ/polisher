# Polisher Gem Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'curb'
require 'json'
require 'tempfile'
require 'pathname'
require 'rubygems/installer'
require 'active_support/core_ext'

require 'polisher/version_checker'

module Polisher
  class Gem
    attr_accessor :name
    attr_accessor :version
    attr_accessor :deps
    attr_accessor :dev_deps
    attr_accessor :files

    def initialize(args={})
      @name     = args[:name]
      @version  = args[:version]
      @deps     = args[:deps]     || []
      @dev_deps = args[:dev_deps] || []
      @files    = args[:files]    || []
    end

    def self.local_versions_for(name)
      @local_db ||= ::Gem::Specification.all
      @local_db.select { |s| s.name == name }.collect { |s| s.version }
    end

    def self.parse(args={})
      metadata = {}

      if args.is_a?(String)
        specj     = JSON.parse(args)
        metadata[:name]     = specj['name']
        metadata[:version]  = specj['version']
        metadata[:deps]     = specj['dependencies']['runtime'].collect { |d| d['name'] }
        metadata[:dev_deps] = specj['dependencies']['development'].collect { |d| d['name'] }

      elsif args.has_key?(:gemspec)
        gemspec  = ::Gem::Specification.load(args[:gemspec])
        metadata[:name]     = gemspec.name
        metadata[:version]  = gemspec.version.to_s
        metadata[:deps]     =
          gemspec.dependencies.select { |dep| dep.type == :runtime }.collect { |dep| dep.name }
        metadata[:dev_deps] =
          gemspec.dependencies.select { |dep| dep.type == :development }.collect { |dep| dep.name }

      elsif args.has_key?(:gem)
        # TODO
      end

      self.new metadata
    end

    def download_gem
      gem_path = "https://rubygems.org/gems/#{@name}-#{@version}.gem"
      curl = Curl::Easy.new(gem_path)
      curl.follow_location = true
      curl.http_get
      gemf = curl.body_str
    end

    def refresh_files
      gemf = download_gem
      tgem = Tempfile.new(@name)
      tgem.write gemf
      tgem.close

      @files = []
      pkg = ::Gem::Installer.new tgem.path, :unpack => true
      Dir.mktmpdir { |dir|
        pkg.unpack dir
        Pathname(dir).find do |path|
          pathstr = path.to_s.gsub(dir, '')
          @files << pathstr unless pathstr.blank?
        end
      }
      @files
    end

    # Retrieve metadata and contents
    def self.retrieve(name)
      gem_json_path = "https://rubygems.org/api/v1/gems/#{name}.json"
      spec = Curl::Easy.http_get(gem_json_path).body_str
      gem  = self.parse spec
      gem.refresh_files
      gem
    end

    # Retreive available versions of gem,
    # optionally w/ versions of deps & dev_deps, recursively
    def versions(args={})
      recursive = args[:recursive]
      dev_deps  = args[:dev_deps]

      versions = { self.name => Polisher::VersionChecker.versions_for(self.name) }
      if recursive
        self.deps.each { |dep|
          unless versions.has_key?(dep)
            gem = Polisher::Gem.retrieve(dep)
            versions.merge! gem.versions
          end
        }

        if dev_deps
          self.dev_deps.each { |dep|
            unless versions.has_key?(dep)
              gem = Polisher::Gem.retrieve(dep)
              versions.merge! gem.versions
            end
          }
        end
      end
      versions
    end
  end # class Gem
end # module Polisher
