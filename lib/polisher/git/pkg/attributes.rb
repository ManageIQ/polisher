# Polisher Git Package Attributes Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/rpm/spec'
require 'polisher/util/git_cache'

module Polisher
  module Git
    module PkgAttributes
      attr_accessor :name
      attr_accessor :version

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

      # Return boolean indicating if spec file exists
      def spec?
        include? spec_file
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

      # Return boolean indicating if package is marked as dead (retired/obsolete/etc)
      def dead?
        in_repo { File.exist?('dead.package') }
      end
    end # module PkgAttributes
  end # module Git
end # module Polisher
