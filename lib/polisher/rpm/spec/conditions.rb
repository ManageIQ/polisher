# RPM Spec Conditions Mixin
#
# Licensed under the MIT license
# Copyright (C) 2016 Red Hat, Inc.

require 'polisher/rpm/condition'

module Polisher
  module RPM
    module SpecConditions
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end
    end # module SpecConditions
  end # module RPM
end # module Polisher
