# RPM Spec Gem Requirements Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module RPM
    module SpecGemRequirements
      # Return all the Requires for the specified gem
      def requirements_for_gem(gem_name)
        requires.select { |r| r.gem_name == gem_name }
      end

      # Return all the BuildRequires for the specified gem
      def build_requirements_for_gem(gem_name)
        build_requires.select { |r| r.gem_name == gem_name }
      end

      # Return bool indicating if this spec specifies all the
      # requirements in the specified gem dependency
      #
      # @param [Gem::Dependency] gem_dep dependency which to retreive / compare
      # requirements
      def has_all_requirements_for?(gem_dep)
        require 'gem2rpm'

        reqs = requirements_for_gem gem_dep.name
        # create a spec requirement dependency for each expanded subrequirement,
        # verify we can find a match for that
        gem_dep.requirement.to_s.split(',').all? do |greq|
          Gem2Rpm::Helpers.expand_requirement([greq.split]).all? do |ereq|
            tereq = Requirement.new :name      => "#{requirement_prefix}(#{gem_dep.name})",
                                    :condition => ereq.first,
                                    :version   => ereq.last.to_s
            reqs.any? { |req| req.matches?(tereq) }
          end
        end
      end

      # Return all gem Requires
      def gem_requirements
        requires.select { |r| r.gem? }
      end

      # Return all gem BuildRequires
      def gem_build_requirements
        build_requires.select { |r| r.gem? }
      end

      # Return all non gem Requires
      def non_gem_requirements
        requires.select { |r| !r.gem? }
      end

      # Return all non gem BuildRequires
      def non_gem_build_requirements
        build_requires.select { |r| !r.gem? }
      end

      # Return all gem requirements _not_ in the specified gem
      def extra_gem_requirements(gem)
        gem_reqs = gem.deps.collect { |d| requirements_for_gem(d.name) }.flatten
        gem_requirements - gem_reqs
      end

      # Return all gem build requirements _not_ in the specified gem
      def extra_gem_build_requirements(gem)
        gem_reqs = gem.dev_deps.collect { |d| build_requirements_for_gem(d.name) }.flatten
        gem_build_requirements - gem_reqs
      end
    end # module SpecGemRequirements
  end  # module RPM
end # module Polisher
