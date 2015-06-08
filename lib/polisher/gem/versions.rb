# Polisher Gem Versions Mixin
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/adaptors/version_checker'

module Polisher
  module GemVersions
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Retrieve list of the versions of the specified gem installed locally
      #
      # @param [String] name name of the gem to lookup
      # @param [Callable] bl optional block to invoke with versions retrieved
      # @return [Array<String>] list of versions of gem installed locally
      def local_versions_for(name, &bl)
        silence_warnings do
          @local_db ||= ::Gem::Specification.all
        end
        versions = @local_db.select { |s| s.name == name }.collect { |s| s.version }
        bl.call(:local_gem, name, versions) unless bl.nil?
        versions
      end

      # Retrieve all versions of gem available on rubygems
      def remote_versions_for(name)
        require 'json'

        client.url = "https://rubygems.org/api/v1/versions/#{name}.json"
        client.follow_location = true
        client.http_get
        json = JSON.parse(client.body_str)
        json.collect { |version| version['number'] }
      end

      # Retieve latest version of gem available on rubygems
      def latest_version_of(name)
        remote_versions_for(name).collect { |v| ::Gem::Version.new v }.max.to_s
      end
    end # module ClassMethods

    # Retreive versions of gem available in all configured targets (optionally recursively)
    #
    # @param [Hash] args hash of options to configure retrieval
    # @option args [Boolean] :recursive indicates if versions of dependencies
    # should also be retrieved
    # @option args [Boolean] :dev_deps indicates if versions of development
    # dependencies should also be retrieved
    # @retrieve versions of all gem dependencies available in configured targets
    def dependency_versions(args = {}, &bl)
      versions   = args[:versions] || {}
      check_deps = args[:dev] ? dev_deps : deps

      check_deps.each do |dep|
        unless versions.key?(dep.name)
          begin
            gem = Polisher::Gem.retrieve(dep.name)
            versions.merge! gem.versions(args, &bl)
          rescue
            unknown = Polisher::VersionChecker.unknown_version(:all, dep.name, &bl)
            versions.merge! dep.name => unknown
          end
        end

        args[:versions] = versions
      end

      versions
    end

    # (and dependencies if specified)
    def versions(args = {}, &bl)
      local_args = Hash[args]
      recursive  = local_args[:recursive]
      dev_deps   = local_args[:dev_deps]
      versions   = local_args[:versions] || {}

      gem_versions = Polisher::VersionChecker.versions_for(name, &bl)
      versions.merge! name => gem_versions
      local_args[:versions] = versions

      if recursive
        versions.merge! dependency_versions local_args, &bl
        versions.merge! dependency_versions local_args.merge(:dev => true), &bl if dev_deps
      end

      versions
    end # module ClassMethods
  end # module GemVersions
end # module Polisher
