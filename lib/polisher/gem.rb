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
require 'polisher/gem_cache'

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

    def initialize(args={})
      @spec     = args[:spec]
      @name     = args[:name]
      @version  = args[:version]
      @deps     = args[:deps]     || []
      @dev_deps = args[:dev_deps] || []
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
    #
    # @return [String] binary gem contents
    def download_gem
      cached = GemCache.get(@name, @version)
      return cached unless cached.nil?

      gem_path = "https://rubygems.org/gems/#{@name}-#{@version}.gem"
      curl = Curl::Easy.new(gem_path)
      curl.follow_location = true
      curl.http_get
      gemf = curl.body_str

      GemCache.set(@name, @version, gemf)
      gemf
    end

    # Returns path to downloaded gem
    #
    # @return [String] path to downloaded gem
    def downloaded_gem_path
      # ensure gem is downloaded
      self.download_gem
      GemCache.path_for(@name, @version)
    end

    # Unpack files & return unpacked directory
    #
    # If block is specified, it will be invoked
    # with directory after which directory will be removed
    def unpack(&bl)
      dir = nil
      pkg = ::Gem::Installer.new downloaded_gem_path, :unpack => true

      if bl
        Dir.mktmpdir { |dir|
          bl.call dir
        }
      else
        dir = Dir.mktmpdir
        pkg.unpack dir
      end

      dir
    end

    # Iterate over each file in gem invoking block with path
    def each_file(&bl)
      self.unpack do |dir|
        Pathname(dir).find do |path|
          next if path.to_s == dir.to_s
          bl.call path
        end
      end
    end

    # Retrieve the list of paths to files in the gem
    #
    # @return [Array<String>] list of files in the gem
    def file_paths
      @file_paths ||= begin
        files = []
        self.each_file do |path|
          pathstr = path.to_s.gsub("#{dir}/", '')
          files << pathstr unless pathstr.blank?
        end
        files
      end
    end

    # Retrieve gem metadata and contents from rubygems.org
    #
    # @param [String] name string name of gem to retrieve
    # @return [Polisher::Gem] representation of gem
    def self.retrieve(name)
      gem_json_path = "https://rubygems.org/api/v1/gems/#{name}.json"
      spec = Curl::Easy.http_get(gem_json_path).body_str
      gem  = self.parse spec
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

    # Scan gem for vendored dependencies
    def vendored
      vfiles = self.file_paths.select { |f| f.include?('vendor/') }
      vpkgs  = {}
      vfiles.each { |f|
        vf = f.split('/')
        vname = vf[vf.index('vendor') + 1]
        next if vname == vf.last # only process vendor'd dirs
        vversion = nil
        #vf.last.downcase == 'version.rb' # TODO set vversion from version.rb
        vpkgs[vname] = vversion
      }
      vpkgs
    end

    # Return diff of content in this gem against other
    def diff(other)
    end

  end # class Gem
end # module Polisher
