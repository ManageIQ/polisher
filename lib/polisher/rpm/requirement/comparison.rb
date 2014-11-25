# Polisher RPM Requirement Gem Comparison Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/core'

module Polisher
  module RPM
    module RequirementComparison
      def ==(other)
        @br        == other.br &&
        @name      == other.name &&
        @condition == other.condition &&
        @version   == other.version
      end

      # Greatest Common Denominator,
      # Max version in list that is less than the local version
      def gcd(versions)
        require 'versionomy'
        lversion = Versionomy.parse(version)
        versions.collect { |v| Versionomy.parse(v) }
                .sort { |a, b| a <=> b }.reverse
                .find { |v| v < lversion }.to_s
      end

      # Minimum gem version which satisfies this dependency
      def min_satisfying_version
        require 'versionomy'
        return "0.0"   if version.nil?      ||
                          condition == '<'  ||
                          condition == '<='
        return version if condition == '='  ||
                          condition == '>='
        Versionomy.parse(version).bump(:tiny).to_s # condition == '>'
      end

      # Max gem version which satisfies this dependency
      #
      # Can't automatically deduce in '<' case, so if that is the conditional
      # we require a version list, and will return the gcd from it
      def max_satisfying_version(versions = nil)
        return Float::INFINITY if version.nil?      ||
                                  condition == '>'  ||
                                  condition == '>='
        return version         if condition == '='  ||
                                  condition == '<='

        raise ArgumentError    if versions.nil?
        gcd(versions)
      end

      # Minimum gem version for which this dependency fails
      def min_failing_version
        require 'versionomy'
        raise ArgumentError if version.nil?
        return "0.0"        if condition == '>'  ||
                               condition == '>='
        return version      if condition == '<'
        Versionomy.parse(version).bump(:tiny).to_s # condition == '<=' and '='
      end

      # Max gem version for which this dependency fails
      #
      # Can't automatically deduce in '>=', and '=' cases, so if that is the
      # conditional we require a version list, and will return the gcd from it
      def max_failing_version(versions = nil)
        raise ArgumentError if version.nil?      ||
                               condition == '<=' ||
                               condition == '<'
        return version      if condition == '>'

        raise ArgumentError if versions.nil?
        gcd(versions)
      end

      # Return bool indicating if requirement matches specified
      # depedency.
      #
      # Comparison mechanism will depend on type of class
      # passed to this. Valid types include
      # - Polisher::RPM::Requirements
      # - ::Gem::Dependency
      def matches?(dep)
        require 'gem2rpm'

        return self == dep      if dep.is_a?(self.class)
        raise ArgumentError unless dep.is_a?(::Gem::Dependency)

        return false if !gem? || gem_name != dep.name
        return true  if  version.nil?

        Gem2Rpm::Helpers.expand_requirement([dep.requirement.to_s.split])
                        .any? { |req| req.first == condition && req.last.to_s == version }
      end
    end # module RequirementComparison
  end # module RPM
end # module Polisher
