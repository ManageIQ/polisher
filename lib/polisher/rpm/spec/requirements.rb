# RPM RPM Spec Requirements Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2016 Red Hat, Inc.

require 'polisher/rpm/requirement'

module Polisher
  module RPM
    module SpecRequirements
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
    end # module SpecRequirements
  end # module RPM
end # module Polisher
