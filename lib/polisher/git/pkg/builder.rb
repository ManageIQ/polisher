# Polisher Git Package Builder Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module Git
    module PkgBuilder
      # Build the srpm
      def build_srpm
        require 'awesome_spawn'

        require_cmd! pkg_cmd
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
        require 'polisher/targets/koji'

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
    end # module PkgBuilder
  end # module Git
end # module Polisher
