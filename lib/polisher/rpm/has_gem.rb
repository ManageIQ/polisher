# RPM Has Gem Module
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/logger'

module Polisher
  module RPM
    module HasGem
      # .gem file associated with the RPM specfile
      attr_accessor :gem

      # Return gem corresponding to spec name/version
      def upstream_gem
        @gem, @update_gem = nil, false if @update_gem
        @gem ||= Polisher::Gem.from_rubygems gem_name, version
      end

      # Return list of gem dependencies for which we have no
      # corresponding requirements
      def missing_deps_for(gem)
        # Comparison by name here assuming if it is in existing spec,
        # spec author will have ensured versions are correct for their purposes
        gem.deps.select { |dep| requirements_for_gem(dep.name).empty? }
      end

      # Return list of gem dev dependencies for which we have
      # no corresponding requirements
      def missing_dev_deps_for(gem)
        # Same note as in #missing_deps_for above
        gem.dev_deps.select { |dep| build_requirements_for_gem(dep.name).empty? }
      end

      # Return list of dependencies of upstream gem which
      # have not been included
      def excluded_deps
        missing_deps_for(upstream_gem)
      end

      # Return boolean indicating if the specified gem is on excluded list
      def excludes_dep?(gem_name)
        excluded_deps.any? { |d| d.name == gem_name }
      end

      # Return list of dev dependencies of upstream gem which
      # have not been included
      def excluded_dev_deps
        missing_dev_deps_for(upstream_gem)
      end

      # Return boolean indicating if the specified gem is on
      # excluded dev dep list
      def excludes_dev_dep?(gem_name)
        excluded_dev_deps.any? { |d| d.name == gem_name }
      end
    end # module HasGem
  end # module RPM
end # module Polisher
