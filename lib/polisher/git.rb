# Polisher Git Entity Representations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'tmpdir'
require 'awesome_spawn'

require 'polisher/core'
require 'polisher/rpmspec'
require 'polisher/git_cache'
require 'polisher/vendor'

module Polisher
  # Git Repository
  class GitRepo
    extend ConfHelpers

    # TODO use ruby git api
    conf_attr :git_cmd, '/usr/bin/git'

    def git_cmd
      self.class.git_cmd
    end

    attr_accessor :url

    def initialize(args={})
      @url  = args[:url]
    end

    def path
      GitCache.path_for(@url)
    end

    def clone
      AwesomeSpawn.run "#{git_cmd} clone #{url} #{path}"
    end

    def cloned?
      File.directory?(path)
    end

    def in_repo
      Dir.chdir path do
        yield
      end
    end

    def file_paths
      in_repo { Dir['**/*'] }
    end

    # Note be careful when invoking:
    def reset!
      in_repo { AwesomeSpawn.run "#{git_cmd} reset HEAD~ --hard" }
      self
    end

    def pull
      in_repo { AwesomeSpawn.run "#{git_cmd} pull" }
      self
    end

    def checkout(tgt)
      in_repo { AwesomeSpawn.run "#{git_cmd} checkout #{tgt}" }
      self
    end

    def commit(msg)
      in_repo { AwesomeSpawn.run "#{git_cmd} commit -m '#{msg}'" }
      self
    end
  end

  # DistGit Package Representation
  class GitPackage < GitRepo
    attr_accessor :name
    attr_accessor :version

    conf_attr :rpm_prefix,   'rubygem-'
    conf_attr :pkg_cmd,      '/usr/bin/fedpkg'
    conf_attr :build_cmd,    '/usr/bin/koji'
    conf_attr :build_tgt,    'rawhide'
    conf_attr :md5sum_cmd,   '/usr/bin/md5sum'
    conf_attr :sed_cmd,      '/usr/bin/sed'
    conf_attr :dist_git_url, 'git://pkgs.fedoraproject.org/'
    conf_attr :fetch_tgt,    'master'

    def initialize(args={})
      @name    = args[:name]
      @version = args[:version]
      super(args)
    end

    # Return full rpm name of package containing optional prefix
    def rpm_name
      @rpm_name ||= "#{rpm_prefix}#{self.name}"
    end

    # Return full srpm file name of package
    def srpm
      @srpm ||= "#{rpm_name}-#{self.version}-1.*.src.rpm"
    end

    # Return full spec file name
    def spec_file
      @spec_path ||= "#{rpm_name}.spec"
    end

    # Return handle to instance of Polisher::RPMSpec corresponding to spec
    def spec
      @spec ||= in_repo { Polisher::RPMSpec.parse File.read(spec_file) }
    end

    # Files representing pkg tracked by git
    def pkg_files
      @pkg_files ||= [spec_file, 'sources', '.gitignore']
    end

    # Override path to reference pkg name
    # @override
    def path
      GitCache.path_for(rpm_name)
    end

    # Alias orig clone method to git_clone
    alias :git_clone :clone

    # Override clone to use PKG_PCMD
    # @override
    def clone
      in_repo do
        AwesomeSpawn.run "#{pkg_cmd} clone #{rpm_name}"
        Dir.glob(rpm_name, '*').each { |f| File.move f, '.' }
        FileUtils.rm_rf rpm_name
      end

      self
    end

    def dead?
      in_repo { File.exists?('dead.package') }
    end

    # Clone / init GitPkg
    def fetch
      clone unless cloned?
      raise Exception, "Dead package detected" if dead?
      checkout fetch_tgt
      reset!
      pull

      self
    end

    # Update the local spec to the specified gem version
    #
    # FIXME this should be removed and calls replaced with self.spec.update_to(gem)
    def update_spec_to(gem)
      in_repo do
        replace_version = "s/Version.*/Version: #{gem.version}/"
        replace_release = "s/Release:.*/Release: 1%{?dist}/"
        [replace_version, replace_release].each do |replace|
          AwesomeSpawn.run "#{sed_cmd} -i '#{replace}' #{spec_file}"
        end
      end
    end

    # Generate new sources file
    def gen_sources_for(gem)
      in_repo do
        AwesomeSpawn.run "#{md5sum_cmd} #{gem.name}-#{gem.version}.gem > sources"
      end
    end

    # Update git ignore to ignore gem
    def ignore(gem)
      File.open(".gitignore", "w") { |f| f.write "#{gem.name}-#{gem.version}.gem" }
    end

    # Update the local pkg to specified gem
    #
    # @param [Polisher::Gem] gem instance of gem containing metadata to update to
    def update_to(gem)
      update_spec_to  gem
      gen_sources_for gem
      ignore gem
      self
    end

    # Override commit, generate a default msg, always add pkg files
    # @override
    def commit(msg=nil)
      in_repo { AwesomeSpawn.run "#{git_cmd} add #{pkg_files.join(' ')}" }
      super(msg.nil? ? "updated to #{version}" : msg)
      self
    end

    # Build the srpm
    def build_srpm
      in_repo { AwesomeSpawn.run "#{pkg_cmd} srpm" }
      self
    end

    # Run a scratch build
    def scratch_build
      # TODO if build fails, raise error, else return output
      cmd = "#{build_cmd} build --scratch #{build_tgt} #{srpm}"
      in_repo { AwesomeSpawn.run(cmd) }
      self
    end

    # Build the pkg
    def build
      build_srpm
      scratch_build
      self
    end

    # Retrieve list of the version of the specified package in git
    #
    # @param [String] name name of package to lookup
    # @param [Callable] bl optional block to invoke with version retrieved
    # @return [String] version retrieved, or nil if none found
    def self.version_for(name, &bl)
      version = nil
      gitpkg = self.new :name => name
      gitpkg.url = "#{dist_git_url}#{gitpkg.rpm_name}.git"
      gitpkg.git_clone
      begin
        version = gitpkg.spec.version
      rescue => e
      end

      bl.call(:git, name, [version]) unless(bl.nil?) 
      version
    end
  end # class GitPackage

  # Upstream Git project representation
  class GitProject < GitRepo
    include HasVendoredDeps

    # Override vendored to ensure repo is
    # cloned before retrieving modules
    def vendored
      clone unless cloned?
      super
    end
  end
end # module Polisher
