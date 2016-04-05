# Polisher RPM Conditon (%if / %endif block
#
# Licensed under the MIT license
# Copyright (C) 2016 Red Hat, Inc.

module Polisher
  module RPM
    class Condition
      attr_accessor :str, :parent, :children, :requires, :build_requires

      def initialize(args = {})
        @str            = args[:str]
        @parent         = args[:parent]
        @children       = args[:children]       || []
        @requires       = args[:requires]       || []
        @build_requires = args[:build_requires] || []
      end

      def has_requires?
        !requires.empty? || children.any? { |child| child.has_requires? }
      end

      def expanded_requires
        "%if #{str}\n" +
        requires.collect { |r| "Requires: #{r.str}\n" }.join +
        "%endif"
      end

      def has_build_requires?
        !build_requires.empty? || children.any? { |child| child.has_build_requires? }
      end

      def expanded_build_requires
        "%if #{str}\n" +
        build_requires.collect { |r| "BuildRequires: #{r.str}\n" }.join +
        "%endif"
      end

      def self.extra_requires(conditions, requires)
        requires.select { |req| !conditions.any? { |condition| condition.requires.include?(req) }}
      end

      def self.extra_build_requires(conditions, build_requires)
        build_requires.select { |req| !conditions.any? { |condition| condition.build_requires.include?(req) }}
      end
    end
  end # module RPM
end # module Polisher
