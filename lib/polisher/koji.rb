# Polisher Koji Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/core'
require 'polisher/component'

module Polisher
  deps = ['awesome_spawn', 'xmlrpc/client', 'active_support',
          'active_support/core_ext/kernel/reporting']
  Component.verify("Koji", *deps) do
    silence_warnings do
      XMLRPC::Config::ENABLE_NIL_PARSER = true
      XMLRPC::Config::ENABLE_NIL_CREATE = true
    end

    class Koji
      include ConfHelpers

      conf_attr :koji_url, 'koji.fedoraproject.org/kojihub'
      conf_attr :koji_tag, 'f21'
      conf_attr :package_prefix, 'rubygem-'

      # XXX don't like having to shell out to koji but quickest
      # way to get an authenticated session so as to launch builds
      conf_attr :build_cmd, '/usr/bin/koji'
      conf_attr :build_tgt,    'rawhide'

      def self.koji_tags
        [koji_tag].flatten
      end

      def self.package_prefixes
        [package_prefix].flatten
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
        versions = versions_for name
        versions.include?(version)
      end

      # Return bool indicating if koji has a build which
      # satisfies the specified ruby dependency
      def self.has_build_satisfying?(name, version)
        dep = ::Gem::Dependency.new name, version
        versions_for(name).any? { |v| dep.match?(name, v) }
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
        versions = tagged_versions_for(name).values.flatten.uniq
        bl.call(:koji, name, versions) unless bl.nil?
        versions
      end

      def self.tagged_versions_for(name)
        versions = {}
        koji_tags.each do |tag|
          versions[tag] = versions_for_tag(name, tag).flatten.uniq
        end
        versions
      end

      def self.tagged_version_for(name)
        versions = {}
        tagged_versions_for(name).each do |tag, tagged_versions|
          versions[tag] = tagged_versions.first
        end
        versions
      end

      def self.versions_for_tag(name, tag)
        metadata =
          package_prefixes.collect do |prefix|
            #                         tag  event inherit prefix latest
            client.call('listTagged', tag, nil,  true,   nil,   false,
                        "#{prefix}#{name}")
          end

        metadata.flatten.collect { |b| b['version'] }.uniq
      end

      # Run a build against the specified target using the specified rpm
      def self.build(args = {})
        require_cmd! build_cmd

        target  = args[:target] || build_tgt
        srpm    = args[:srpm]
        scratch = args[:scratch] ? '--scratch' : ''

        cmd = "#{build_cmd} build #{scratch} #{target} #{srpm}"
        result = AwesomeSpawn.run(cmd)
        url = parse_url(result.output)
        raise url if result.exit_status != 0
        url
      end

      # Parse a koji build url from output
      def self.parse_url(output)
        task_info = output.lines.detect { |l| l =~ /Task info:.*/ }
        task_info ? task_info.split.last : ''
      end

      # def self.build_logs(url) # TODO

      # Return diff between list of packages in two tags in koji
      def self.diff(tag1, tag2)
        #                                   tag event inherit prefix latest
        builds1 = client.call('listTagged', tag1, nil, false, nil, true)
        builds2 = client.call('listTagged', tag2, nil, false, nil, true)
        builds  = {}
        builds1.each do |build|
          name         = build['package_name']
          version      = build['version']
          builds[name] = {tag1 => version}
        end

        builds2.each do |build|
          name = build['package_name']
          builds[name] ||= {}
          builds[name][tag2] = build['version']
        end

        builds
      end
    end # class Koji
  end # Component.verify("Koji")
end # module Polisher
