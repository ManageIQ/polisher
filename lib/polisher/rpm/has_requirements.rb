# RPM Has Requirements Module
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/logger'

module Polisher
  module RPM
    module HasRequirements
      # Return all the Requires for the specified gem
      def requirements_for_gem(gem_name)
        @metadata[:requires].nil? ? [] :
        @metadata[:requires].select { |r| r.gem_name == gem_name }
      end

      # Return all the BuildRequires for the specified gem
      def build_requirements_for_gem(gem_name)
        @metadata[:build_requires].nil? ? [] :
        @metadata[:build_requires].select { |r| r.gem_name == gem_name }
      end

      # Return bool indicating if this spec specifies all the
      # requirements in the specified gem dependency
      #
      # @param [Gem::Dependency] gem_dep dependency which to retreive / compare
      # requirements
      def has_all_requirements_for?(gem_dep)
        reqs = self.requirements_for_gem gem_dep.name
        # create a spec requirement dependency for each expanded subrequirement,
        # verify we can find a match for that
        gem_dep.requirement.to_s.split(',').all? { |greq|
          Gem2Rpm::Helpers.expand_requirement([greq.split]).all? { |ereq|
            tereq = Requirement.new :name      => "#{requirement_prefix}(#{gem_dep.name})",
                                    :condition => ereq.first,
                                    :version   => ereq.last.to_s
            reqs.any? { |req| req.matches?(tereq)}
          }
        }
      end

      # Return all gem Requires
      def gem_requirements
        @metadata[:requires].nil? ? [] :
        @metadata[:requires].select { |r| r.gem? }
      end

      # Return all gem BuildRequires
      def gem_build_requirements
        @metadata[:build_requires].nil? ? [] :
        @metadata[:build_requires].select { |r| r.gem? }
      end

      # Return all non gem Requires
      def non_gem_requirements
        @metadata[:requires].nil? ? [] :
        @metadata[:requires].select { |r| !r.gem? }
      end

      # Return all non gem BuildRequires
      def non_gem_build_requirements
        @metadata[:build_requires].nil? ? [] :
        @metadata[:build_requires].select { |r| !r.gem? }
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # RPM Spec Requirement Prefix
        def requirement_prefix
          Requirement.prefix
        end

        def package_prefix
          requirement_prefix
        end
      end # module ClassMethods

      def requirement_prefix
        self.class.requirement_prefix
      end
    end # module HasRequirements
  end # module RPM
end # module Polisher
