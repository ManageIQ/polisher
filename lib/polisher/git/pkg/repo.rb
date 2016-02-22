# Polisher Git Package Repo Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'fileutils'
require 'polisher/util/error'

module Polisher
  module Git
    module PkgRepo
      # Alias orig clone method to git_clone
      alias :git_clone :clone
      # Override clone to use PKG_PCMD
      # @override
      def clone
        require_dep! 'awesome_spawn'
        require_cmd! pkg_cmd
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

      # Fetch specified target or configured fetch_tgt if not specified
      def fetch(target = nil)
        target = self.class.fetch_tgts.first if target.nil?
        clone unless cloned?
        raise Exception, "Dead package detected" if dead?
        checkout target
        reset!
        pull
        self
      end

      # Return the valid targets, eg those which we can fetch
      def valid_targets
        valid = []
        self.class.fetch_tgts.collect do |target|
          begin
            fetch target
            valid << target
          rescue
            # noop
          end
        end
        valid
      end

      alias :valid_branches :valid_targets

      # Override commit, generate a default msg, always add pkg files
      # @override
      def commit(msg = nil)
        require_dep! 'awesome_spawn'
        require_cmd! git_cmd
        in_repo { AwesomeSpawn.run "#{git_cmd} add #{pkg_files.join(' ')}" }
        super(msg.nil? ? "updated to #{version}" : msg)
        self
      end
    end # module PkgRepo
  end # module Git
end # module Polisher
