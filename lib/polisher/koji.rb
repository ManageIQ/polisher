# Polisher Koji Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/core'
require 'polisher/component'

module Polisher
  deps = ['xmlrpc/client', 'active_support', 'active_support/core_ext/kernel/reporting']
  Component.verify("Koji", *deps) do
    silence_warnings do
      XMLRPC::Config::ENABLE_NIL_PARSER = true
      XMLRPC::Config::ENABLE_NIL_CREATE = true
    end

    class Koji
      extend ConfHelpers

      # TODO Koji#build (on class or instance?)

      conf_attr :koji_url, 'koji.fedoraproject.org/kojihub'
      conf_attr :koji_tag, 'f21'
      conf_attr :package_prefix, 'rubygem-'

      def self.koji_tags
        [koji_tag].flatten
      end

      # Retrieve shared instance of xmlrpc client to use
      def self.client
        @client ||= begin
          url = koji_url.split('/')
          XMLRPC::Client.new(url[0..-2].join('/'),
                             "/#{url.last}")
        end
      end

      # Return bool indiciating if koji has a build exactly
      # matching the specified version
      def self.has_build?(name, version)
        versions = self.versions_for name
        versions.include?(version)
      end

      # Return bool indicating if koji has a build which
      # satisfies the specified ruby dependency
      def self.has_build_satisfying?(name, version)
        dep = ::Gem::Dependency.new name, version
        self.versions_for(name).any? { |v|
          dep.match?(name, v)
        }
      end

      # Return list of tags for which a package exists
      #
      # @param [String] name of package to lookup
      # @return [Hash<String,String>] hash of tag names to package versions for tags
      # which package was found in
      def self.tagged_in(name)
        #                               tagid  userid         pkgid  prefix inherit with_dups
        pkgs = client.call('listPackages', nil, nil, "rubygem-#{name}", nil, false, true)
        pkgs.collect { |pkg| pkg['tag_name'] }
      end

      # Retrieve list of the versions of the specified package in koji
      #
      # @param [String] name name of package to lookup
      # @param [Callable] bl optional block to invoke with versions retrieved
      # @return [Array<String>] versions retrieved, empty array if none found
      def self.versions_for(name, &bl)
        # koji xmlrpc call
        builds =
          koji_tags.collect do |tag|
            #                         tag  event inherit prefix latest
            client.call('listTagged', tag, nil,  true,   nil,   false,
                        "#{package_prefix}#{name}")
          end.flatten
        versions = builds.collect { |b| b['version'] }
        bl.call(:koji, name, versions) unless(bl.nil?)
        versions
      end

      # Return diff between list of packages in two tags in koji
      def self.diff(tag1, tag2)
        builds1 = client.call('listTagged', tag1, nil, false, nil, false)
        builds2 = client.call('listTagged', tag2, nil, false, nil, false)
        builds  = {}
        builds1.each do |build|
          name         = build['package_name']
          build2       = builds2.find { |b| b['name'] == name }
          version1     = build['version']
          version2     = build2 && build2['version']
          builds[name] = {tag1 => version1, tag2 => version2}
        end

        builds2.each do |build|
          name = build['package_name']
          next if builds.key?(name)

          version = build['version']
          builds[name] = {tag1 => nil, tag2 => version}
        end

        builds
      end
    end # class Koji
  end # Component.verify("Koji")
end # module Polisher
