# Polisher Errata Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  class ErrataBuild
    def self.builds_matching(builds, name)
      builds.collect { |build|
        build_matches?(build, name) ? build_version(build, name) : nil
      }.compact
    end

    def self.build_matches?(build, name)
      pkg, meta = *build.flatten
      pkg =~ /^#{Errata.package_prefix}#{name}-([^-]*)-.*$/
    end

    def self.build_version(build, name)
      pkg, meta = *build.flatten
      pkg.gsub(Errata.package_prefix, '').split('-')[1]
    end
  end # class ErrataBuild
end # module Polisher
