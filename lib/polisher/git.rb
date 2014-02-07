# Polisher Git Entity Representations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

# TODO use ruby git api and others

require 'tmpdir'
require 'awesome_spawn'
require 'polisher/rpmspec'

module Polisher
  # DistGit Package Representation
  class GitPackage
    attr_accessor :name
    attr_accessor :version

    # TODO these should be to be configurable
    PKG_CMD      = '/usr/bin/fedpkg'
    GIT_CMD      = '/usr/bin/git'
    BUILD_CMD    = '/usr/bin/koji'
    BUILD_TGT    = 'rawhide'
    MD5SUM_CMD   = '/usr/bin/md5sum'
    SED_CMD      = '/usr/bin/sed'
    RPM_PREFIX   = 'rubygem-'
    DIST_GIT_URL = 'git://pkgs.fedoraproject.org/'

    def initialize(args={})
      @name    = args[:name]
      @version = args[:version]
    end

    # Return full rpm name of package containing optional prefix
    def rpm_name
      "#{RPM_PREFIX}#{self.name}"
    end

    # Return full srpm file name of package
    def srpm
      "#{rpm_name}-#{self.version}-1.*.src.rpm"
    end

    # Return full spec file name
    def spec
      "#{rpm_name}.spec"
    end

    # Clone git package
    #
    # @param [String] name name of package to clone
    # @return [Polisher::GitPackage] git package instance representing cloned package
    def self.clone(name)
      rpm_name = "#{RPM_PREFIX}#{name}"

      unless File.directory? rpm_name
        AwesomeSpawn.run "#{PKG_CMD} clone #{rpm_name}"
      end
      
      # cd into working directory
      Dir.chdir rpm_name

      if File.exists? 'dead.package'
        raise Exception, "Dead package detected"
      end
      
      # checkout the latest rawhide
      # TODO allow other branches to be specified
      AwesomeSpawn.run "#{GIT_CMD} checkout master"
      AwesomeSpawn.run "#{GIT_CMD} reset HEAD~ --hard"
      AwesomeSpawn.run "#{GIT_CMD} pull"

      self.new :name => name
    end

    # Update the locally cloned package to the specified gem version
    #
    # @param [Polisher::Gem] gem instance of gem containing metadata to update to
    def update_to(gem)
      # TODO use Polisher::RPMSpec to update spec
      AwesomeSpawn.run "#{SED_CMD} -i 's/Version.*/Version: #{gem.version}/' #{spec}"
      AwesomeSpawn.run "#{SED_CMD} -i 's/Release:.*/Release: 1%{?dist}/' #{spec}"
      AwesomeSpawn.run "#{MD5SUM_CMD} #{gem.name}-#{gem.version}.gem > sources"
      File.open(".gitignore", "w") { |f| f.write "#{gem.name}-#{gem.version}.gem" }
    end

    # Build the locally cloned package using the configured build command
    def build
      # build srpm
      AwesomeSpawn.run "#{PKG_CMD} srpm"
      
      # attempt to build packages
      AwesomeSpawn.run "#{BUILD_CMD} build --scratch #{BUILD_TGT} #{srpm}"
      # TODO if build fails, spit out error, exit
    end

    # Return boolean indicating if package spec has a %check section
    #
    # @return [Boolean] true/false depending on whether or not spec has %check
    def has_check?
      File.open(spec, "r") do |spec|
        spec.lines.any? { |line| line.include?("%check") }
      end 
    end

    # Command the local package to the local git repo
    def commit
      # git add spec, git commit w/ message
      AwesomeSpawn.run "#{GIT_CMD} add #{spec} sources .gitignore"
      #`git add #{gem_name}-#{version}.gem`
      AwesomeSpawn.run "#{GIT_CMD} commit -m 'updated to #{self.version}'"
    end

    # Retrieve list of the version of the specified package in git
    #
    # @param [String] name name of package to lookup
    # @param [Callable] bl optional block to invoke with version retrieved
    # @return [String] version retrieved, or nil if none found
    def self.version_for(name, &bl)
      rpm_name = "#{RPM_PREFIX}#{name}"
      version = nil

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do |path|
          version = nil
          AwesomeSpawn.run "#{GIT_CMD} clone #{DIST_GIT_URL}#{rpm_name}.git ."
          begin
            spec = Polisher::RPMSpec.parse(File.read("#{rpm_name}.spec"))
            version = spec.version
          rescue => e
          end
        end
      end

      bl.call(:git, name, [version]) unless(bl.nil?) 
      version
    end
  end # class GitPackage

  # Upstream Git project representation
  class GitProject
    # TODO scan project for vendored components
    def vendored
    end
  end
end # module Polisher
