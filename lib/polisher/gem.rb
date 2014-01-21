# Polisher Gem Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'curb'
require 'json'
require 'yaml'
require 'tempfile'
require 'pathname'
require 'rubygems/installer'
require 'active_support/core_ext'

require 'polisher/version_checker'

module Polisher
  class Gem
    GEM_CMD      = '/usr/bin/gem'

    # Common files shipped in gems that we should ignore
    IGNORE_FILES = ['.gemtest', '.gitignore', '.travis.yml',
                    /.*.gemspec/, /Gemfile.*/, 'Rakefile',
                    /rspec.*/, '.yardopts', '.rvmrc']

    # TODO also mark certain files to be tagged as %{doc}

    attr_accessor :spec
    attr_accessor :name
    attr_accessor :version
    attr_accessor :deps
    attr_accessor :dev_deps
    attr_accessor :files

    def initialize(args={})
      @spec     = args[:spec]
      @name     = args[:name]
      @version  = args[:version]
      @deps     = args[:deps]     || []
      @dev_deps = args[:dev_deps] || []
      @files    = args[:files]    || []
    end

    # Return bool indiicating if the specified file is on the IGNORE_FILES list
    def self.ignorable_file?(file)
      IGNORE_FILES.any? do |ignore|
        ignore.is_a?(Regexp) ? ignore.match(file) : ignore == file
      end
    end

    # Retrieve list of the versions of the specified gem installed locally
    #
    # @param [String] name name of the gem to lookup
    # @param [Callable] bl optional block to invoke with versions retrieved
    # @return [Array<String>] list of versions of gem installed locally
    def self.local_versions_for(name, &bl)
      @local_db ||= ::Gem::Specification.all
      versions = @local_db.select { |s| s.name == name }.collect { |s| s.version }
      bl.call(:local_gem, name, versions) unless(bl.nil?) 
      versions
    end

    # Parse the specified gemspec & return new Gem instance from metadata
    # 
    # @param [String,Hash] args contents of actual gemspec of option hash
    # specifying location of gemspec to parse
    # @option args [String] :gemspec path to gemspec to load / parse
    # @return [Polisher::Gem] gem instantiated from gemspec metadata
    def self.parse(args={})
      metadata = {}

      if args.is_a?(String)
        specj     = JSON.parse(args)
        metadata[:spec]    = specj
        metadata[:name]    = specj['name']
        metadata[:version] = specj['version']

        metadata[:deps] =
          specj['dependencies']['runtime'].collect { |d|
            ::Gem::Dependency.new d['name'], *d['requirements'].split(',')
          }

        metadata[:dev_deps] =
          specj['dependencies']['development'].collect { |d|
            ::Gem::Dependency.new d['name'], d['requirements'].split(',')
          }

      elsif args.has_key?(:gemspec)
        gemspec  = ::Gem::Specification.load(args[:gemspec])
        metadata[:spec]    = gemspec # TODO to json
        metadata[:name]    = gemspec.name
        metadata[:version] = gemspec.version.to_s

        metadata[:deps] =
          gemspec.dependencies.select { |dep|
            dep.type == :runtime
          }.collect { |dep| dep }

        metadata[:dev_deps] =
          gemspec.dependencies.select { |dep|
            dep.type == :development
          }.collect { |dep| dep }

      elsif args.has_key?(:gem)
        # TODO
      end

      self.new metadata
    end

    # Download the gem and return the binary file contents as a string
    # @return [String] binary gem contents
    def download_gem
      gem_path = "https://rubygems.org/gems/#{@name}-#{@version}.gem"
      curl = Curl::Easy.new(gem_path)
      curl.follow_location = true
      curl.http_get
      gemf = curl.body_str
    end

    # Refresh the gem spec
    def refresh_spec
      gemf = download_gem
      tgem = Tempfile.new(@name)
      tgem.write gemf
      tgem.close

      @spec = YAML.load `#{GEM_CMD} specification #{tgem.path}`

      # update deps, dev_deps
      @deps =
        @spec.dependencies.select { |dep|
          dep.type == :runtime
        }.collect { |dep| dep }

      @dev_deps =
        @spec.dependencies.select { |dep|
          dep.type == :development
        }.collect { |dep| dep }
    end

    # Retrieve the list of files in the gem
    #
    # @return [Array<String>] list of files in the gem
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
          next if path.to_s == dir.to_s
          pathstr = path.to_s.gsub("#{dir}/", '')
          @files << pathstr unless pathstr.blank?
        end
      }
      @files
    end

    # Retrieve gem metadata and contents from rubygems.org
    #
    # @param [String] name string name of gem to retrieve
    # @return [Polisher::Gem] representation of gem
    def self.retrieve(name)
      gem_json_path = "https://rubygems.org/api/v1/gems/#{name}.json"
      spec = Curl::Easy.http_get(gem_json_path).body_str
      gem  = self.parse spec
      gem.refresh_files
      gem
    end

    # Retreive versions of gem available in all configured targets (optionally recursively)
    #
    # @param [Hash] args hash of options to configure retrieval
    # @option args [Boolean] :recursive indicates if versions of dependencies
    # should also be retrieved
    # @option args [Boolean] :dev_deps indicates if versions of development
    # dependencies should also be retrieved
    # @return [Hash<name,versions>] hash of name to list of versions for gem
    # (and dependencies if specified)
    def versions(args={}, &bl)
      recursive = args[:recursive]
      dev_deps  = args[:dev_deps]

      versions  = args[:versions] || {}
      versions.merge!({ self.name => Polisher::VersionChecker.versions_for(self.name, &bl) })
      args[:versions] = versions

      if recursive
        self.deps.each { |dep|
          unless versions.has_key?(dep.name)
            gem = Polisher::Gem.retrieve(dep.name)
            versions.merge! gem.versions(args, &bl)
          end
        }

        if dev_deps
          self.dev_deps.each { |dep|
            unless versions.has_key?(dep.name)
              gem = Polisher::Gem.retrieve(dep.name)
              versions.merge! gem.versions(args, &bl)
            end
          }
        end
      end
      versions
    end
  end # class Gem
end # module Polisher
