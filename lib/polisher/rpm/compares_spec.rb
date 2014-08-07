# RPM Spec Comparison Module
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/logger'

module Polisher
  module RPM
    module ComparesSpec
      # Compare this spec to a sepecified upstream gem source
      # and return result.
      #
      # upstream_source should be an instance of Polisher::Gem,
      # Polisher::Gemfile, or other class defining a 'deps'
      # accessor that returns an array of Gem::Requirement dependencies
      #
      # Result will be a hash containing the shared dependencies as
      # well as those that differ and their respective differences
      def compare(upstream_source)
        same = {}
        diff = {}
        upstream_source.deps.each do |d|
          spec_reqs = requirements_for_gem(d.name)
          spec_reqs_specifier = spec_reqs.empty? ? nil :
               spec_reqs.collect { |req| req.specifier }

          if spec_reqs.nil?
            diff[d.name] = {:spec     => nil,
                            :upstream => d.requirement.to_s}

          elsif !spec_reqs.any? { |req| req.matches?(d) } ||
                !self.has_all_requirements_for?(d)
            diff[d.name] = {:spec     => spec_reqs_specifier,
                            :upstream => d.requirement.to_s}

          elsif !diff.has_key?(d.name)
            same[d.name] = {:spec     => spec_reqs_specifier,
                            :upstream => d.requirement.to_s}
          end
        end

        @metadata[:requires].each do |req|
          next unless req.gem?

          upstream_dep = upstream_source.deps.find { |d| d.name == req.gem_name }

          if upstream_dep.nil?
            diff[req.gem_name] = {:spec     => req.specifier,
                                  :upstream => nil}

          elsif !req.matches?(upstream_dep)
            diff[req.gem_name] = {:spec     => req.specifier,
                                  :upstream => upstream_dep.requirement.to_s}

          elsif !diff.has_key?(req.gem_name)
            same[req.gem_name] = {:spec     => req.specifier,
                                  :upstream => upstream_dep.requirement.to_s}
          end
        end unless @metadata[:requires].nil?

        {:same => same, :diff => diff}
      end
    end # module ComparesSpec
  end # module RPM
end # module Polisher
