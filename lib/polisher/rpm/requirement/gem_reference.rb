# Polisher RPM Requirement Gem Reference Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module RPM
    module RequirementGemReference
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Instantiate / return new rpm spec requirements from gem dependency.
        #
        # Because a gem dependency may result in multiple spec requirements
        # this will always return an array of Requirement instances
        def from_gem_dep(gem_dep, br = false)
          require 'gem2rpm'

          gem_dep.requirement.to_s.split(',').collect { |req|
            expanded = Gem2Rpm::Helpers.expand_requirement [req.split]
            expanded.collect { |e|
              new :name      => "#{prefix}(#{gem_dep.name})",
                  :condition => e.first.to_s,
                  :version   => e.last.to_s,
                  :br        => br
            }
          }.flatten
        end
      end # module ClassMethods

      # Whether or not this requirement specified a ruby gem dependency
      def gem?
        !!(str =~ RPM::Spec::SPEC_GEM_REQ_MATCHER)
      end

      # Return the name of the gem which this requirement is for.
      # Returns nil if this is not a gem requirement
      def gem_name
        # XXX need to explicitly run regex here to get $1
        !!(str =~ RPM::Spec::SPEC_GEM_REQ_MATCHER) ? $1 : nil
      end
    end # module RequirementGemReference
  end # module RPM
end # module Polisher
