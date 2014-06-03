# Polisher Git Based Package (distgit) Representation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'fileutils'

require 'polisher/error'
require 'polisher/git/repo'
require 'polisher/rpm/spec'
require 'polisher/component'
require 'polisher/koji'
require 'polisher/logger'

module Polisher
  module Git
    Component.verify("Git::Pkg", 'awesome_spawn') do
      # Git Based Package
      class Pkg < Repo
        extend Logging

        attr_accessor :name
        attr_accessor :version

        conf_attr :rpm_prefix,   'rubygem-'
        conf_attr :pkg_cmd,      '/usr/bin/fedpkg'
        conf_attr :md5sum_cmd,   '/usr/bin/md5sum'
        conf_attr :dist_git_url, 'git://pkgs.fedoraproject.org/'
        conf_attr :fetch_tgt,    'master'

        def self.fetch_tgts
          [fetch_tgt].flatten
        end

        def initialize(args = {})
          @name    = args[:name]
          @version = args[:version]
          super(args)
        end

        # Return full rpm name of package containing optional prefix
        def rpm_name
          @rpm_name ||= "#{rpm_prefix}#{name}"
        end

        # Return full srpm file name of package
        def srpm
          @srpm ||= "#{rpm_name}-#{version}-1.*.src.rpm"
        end

        # Return full spec file name
        def spec_file
          @spec_path ||= "#{rpm_name}.spec"
        end

        # Return handle to instance of Polisher::RPM::Spec corresponding to spec
        def spec
          @spec, @dirty_spec = nil, false if @dirty_spec
          @spec ||= in_repo { Polisher::RPM::Spec.parse File.read(spec_file) }
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
          clobber!
          Dir.mkdir path unless File.directory? path
          in_repo do
            result = AwesomeSpawn.run "#{pkg_cmd} clone #{rpm_name}"
            raise PolisherError,
                  "could not clone #{rpm_name}" unless result.exit_status == 0

            # pkg_cmd will clone into the rpm_name subdir,
            # move everything up a dir
            Dir.foreach("#{rpm_name}/") do |f|
              orig = "#{rpm_name}/#{f}"
              skip = ['.', '..'].include?(f)
              FileUtils.move orig, '.' unless skip
            end

            FileUtils.rm_rf rpm_name
          end

          self
        end

        # Return boolean indicating if package is marked as dead (retired/obsolete/etc)
        def dead?
          in_repo { File.exist?('dead.package') }
        end

        # Clone / init GitPkg
        def fetch(target = nil)
          target = self.class.fetch_tgts.first if target.nil?
          clone unless cloned?
          raise Exception, "Dead package detected" if dead?
          checkout target
          reset!
          pull

          self
        end

        def update_metadata(gem)
          @version = gem.version
        end

        # Update the local spec to the specified gem version
        def update_spec_to(gem)
          in_repo do
            spec.update_to(gem)
            File.write(spec_file, spec.to_string)
            @dirty_spec = true
          end
        end

        # Generate new sources file
        def gen_sources_for(gem)
          in_repo do
            AwesomeSpawn.run "#{md5sum_cmd} #{gem.gem_path} > sources"
            File.write('sources', File.read('sources').gsub("#{GemCache::DIR}/", ''))
          end
        end

        # Update git ignore to ignore gem
        def ignore(gem)
          in_repo do
            nl = File.exist?('.gitignore') ? "\n" : ''
            content = "#{nl}#{gem.name}-#{gem.version}.gem"
            File.open(".gitignore", 'a') { |f| f.write content }
          end
        end

        # Update the local pkg to specified gem
        #
        # @param [Polisher::Gem] gem instance of gem containing metadata to update to
        def update_to(gem)
          update_metadata gem
          update_spec_to gem
          gen_sources_for gem
          ignore gem
          self
        end

        # Override commit, generate a default msg, always add pkg files
        # @override
        def commit(msg = nil)
          in_repo { AwesomeSpawn.run "#{git_cmd} add #{pkg_files.join(' ')}" }
          super(msg.nil? ? "updated to #{version}" : msg)
          self
        end

        # Build the srpm
        def build_srpm
          in_repo do
            begin
              gem = spec.upstream_gem
              FileUtils.rm_f gem.file_name if File.exist?(gem.file_name)
              FileUtils.ln_s gem.gem_path, gem.file_name
              result = AwesomeSpawn.run "#{pkg_cmd} srpm"
              raise result.error unless result.exit_status == 0
            ensure
              FileUtils.rm_f gem.file_name if File.exist?(gem.file_name)
            end
          end
          self
        end

        # Run a scratch build
        def scratch_build
          in_repo do
            Koji.build :srpm    => srpm,
                       :scratch => true
          end
          self
        end

        # Build the pkg
        def build
          build_srpm
          scratch_build
          self
        end

        # Retrieve list of the versions of the specified package in git
        #
        # @param [String] name name of package to lookup
        # @param [Callable] bl optional block to invoke with version retrieved
        # @return [Array<String>] versions retrieved, or empty array if none found
        def self.versions_for(name, &bl)
          version = nil
          gitpkg = new :name => name
          gitpkg.url = "#{dist_git_url}#{gitpkg.rpm_name}.git"
          versions = []
          fetch_tgts.each do |tgt|
            begin
              gitpkg.fetch tgt
              versions << gitpkg.spec.version
            rescue => e
              logger.warn "error retrieving #{name} from #{gitpkg.url}/#{tgt}(distgit): #{e}"
            end
          end

          bl.call(:git, name, versions) unless bl.nil?
          versions
        end
      end # module Pkg
    end # Component.verify("Git::Pkg")
  end # module Git
end # module Polisher
