# Polisher RPM Requirement Attributes Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module RPM
    module RequirementAttributes
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def prefix
          "#{scl_prefix}#{rubygem_prefix}"
        end
      end

      # Bool indiciating if req is a BR
      attr_accessor :br

      # Name of requirement
      attr_accessor :name

      # Condition, eg >=, =, etc
      attr_accessor :condition

      # Version number
      attr_accessor :version

      # Requirement string
      def str
        sp = specifier
        sp.nil? ? "#{@name}" : "#{@name} #{sp}"
      end

      # Specified string
      def specifier
        @version.nil? ? nil : "#{@condition} #{@version}"
      end
    end # module RequirementAttributes
  end # module RPM
end # module Polisher
