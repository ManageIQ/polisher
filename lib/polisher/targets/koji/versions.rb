# Polisher Koji Versions Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module KojiVersions
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Return bool indiciating if koji has a build exactly
      # matching the specified version
      def has_build?(name, version)
        versions = versions_for name
        versions.include?(version)
      end

      # Return bool indicating if koji has a build which
      # satisfies the specified ruby dependency
      def has_build_satisfying?(name, version)
        dep = ::Gem::Dependency.new name, version
        versions_for(name).any? { |v| dep.match?(name, v) }
      end

      # Retrieve list of the versions of the specified package in koji
      #
      # @param [String] name name of package to lookup
      # @param [Callable] bl optional block to invoke with versions retrieved
      # @return [Array<String>] versions retrieved, empty array if none found
      def versions_for(name, &bl)
        # koji xmlrpc call
        versions = tagged_versions_for(name).values.flatten.uniq
        bl.call(:koji, name, versions) unless bl.nil?
        versions
      end

      def tagged_versions_for(name)
        versions = {}
        koji_tags.each do |tag|
          versions[tag] = versions_for_tag(name, tag).flatten.uniq
        end
        versions
      end

      def tagged_version_for(name)
        versions = {}
        tagged_versions_for(name).each do |tag, tagged_versions|
          versions[tag] = tagged_versions.first
        end
        versions
      end

      def versions_for_tag(name, tag)
        metadata =
          package_prefixes.collect do |prefix|
            #                         tag  event inherit prefix latest
            client.call('listTagged', tag, nil,  true,   nil,   false,
                        "#{prefix}#{name}")
          end
        metadata.flatten.collect { |b| b['version'] }.uniq
      end
    end # module ClassMethods
  end # module KojiRpc
end # module Polisher
