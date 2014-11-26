# Polisher Koji RPC Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module KojiDiff
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Return diff between list of packages in two tags in koji
      def diff(tag1, tag2)
        #                                   tag event inherit prefix latest
        builds1 = client.call('listTagged', tag1, nil, false, nil, true)
        builds2 = client.call('listTagged', tag2, nil, false, nil, true)
        builds  = {}
        builds1.each do |build|
          name         = build['package_name']
          build2       = builds2.detect { |b| b['name'] == name }
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
    end # module ClassMethods
  end # module KojiDiff
end # module Polisher
