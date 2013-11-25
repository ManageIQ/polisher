# Polisher DistGit Package Representation
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

# TODO use ruby git api and others

require 'polisher/rpmspec'

module Polisher
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

    def rpm_name
      "#{RPM_PREFIX}#{self.name}"
    end

    def srpm
      "#{rpm_name}-#{self.version}-1.*.src.rpm"
    end

    def spec
      "#{rpm_name}.spec"
    end

    def self.clone(name)
      rpm_name = "#{RPM_PREFIX}#{name}"

      unless File.directory? rpm_name
        `#{PKG_CMD} clone #{rpm_name}`
      end
      
      # cd into working directory
      Dir.chdir rpm_name

      if File.exists? 'dead.package'
        raise Exception, "Dead package detected"
      end
      
      # checkout the latest rawhide
      # TODO allow other branches to be specified
      `#{GIT_CMD} checkout master`
      `#{GIT_CMD} reset HEAD~ --hard`
      `#{GIT_CMD} pull`

      self.new :name => name
    end

    def update_to(gem)
      # TODO use Polisher::RPMSpec to update spec
      `#{SED_CMD} -i "s/Version.*/Version: #{gem.version}/" #{spec}`
      `#{SED_CMD} -i "s/Release:.*/Release: 1%{?dist}/" #{spec}`
      `#{MD5SUM_CMD} #{gem.name}-#{gem.version}.gem > sources`
      File.open(".gitignore", "w") { |f| f.write "#{gem.name}-#{gem.version}.gem" }
    end

    def build
      # build srpm
      `#{PKG_CMD} srpm`
      
      # attempt to build packages
      `#{BUILD_CMD} build --scratch #{BUILD_TGT} #{srpm}`
      # TODO if build fails, spit out error, exit
    end

    def has_check?
      open(spec, "r") do |spec|
        spec.lines.any? { |line| line.include?("%check") }
      end 
    end

    def commit
      # git add spec, git commit w/ message
      `#{GIT_CMD} add #{spec} sources .gitignore`
      #`git add #{gem_name}-#{version}.gem`
      `#{GIT_CMD} commit -m 'updated to #{self.version}'`
    end

    def self.version_for(name, &bl)
      rpm_name = "#{RPM_PREFIX}#{name}"
      version = nil

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do |path|
          version = nil
          `#{GIT_CMD} clone #{DIST_GIT_URL}#{rpm_name}.git . >& /dev/null`
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
end # module Polisher
