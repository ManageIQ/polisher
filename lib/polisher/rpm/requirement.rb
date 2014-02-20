# Polisher RPM Requirement Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'gem2rpm'
require 'versionomy'
require 'active_support/core_ext'

require 'polisher/core'
require 'polisher/gem'

module Polisher
  module RPM
    class Requirement
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
        sp = self.specifier
        sp.nil? ? "#{@name}" : "#{@name} #{sp}"
      end

      # Specified string
      def specifier
        @version.nil? ? nil : "#{@condition} #{@version}"
      end

      def self.parse(str, opts={})
        stra   = str.split
        br = str.include?('BuildRequires')
        name = condition = version = nil

        if str.include?('Requires')
          name      = stra[1] 
          condition = stra[2]
          version   = stra[3]

        else
          name      = stra[0]
          condition = stra[1]
          version   = stra[2]

        end

        req = self.new({:name      => name,
                        :condition => condition,
                        :version   => version,
                        :br        => br}.merge(opts))
        req
      end

      def initialize(args={})
        @br        = args[:br] || false
        @name      = args[:name]
        @condition = args[:condition]
        @version   = args[:version]

        @name.strip!      unless @name.nil?
        @condition.strip! unless @condition.nil?
        @version.strip!   unless @version.nil?
      end

      def ==(other)
        @br        == other.br &&
        @name      == other.name &&
        @condition == other.condition &&
        @version   == other.version
      end

      # Greatest Common Denominator,
      # Max version in list that is less than the local version
      def gcd(versions)
        lversion = Versionomy.parse(self.version)
        versions.collect { |v| Versionomy.parse(v) }.
                 sort { |a,b| a <=> b }.reverse.
                 find { |v| v < lversion }.to_s
      end

      # Minimum gem version which satisfies this dependency
      def min_satisfying_version
        return "0.0"        if self.version.nil?      ||
                               self.condition == '<'  ||
                               self.condition == '<='
        return self.version if self.condition == '='  ||
                               self.condition == '>='
        Versionomy.parse(self.version).bump(:tiny).to_s # self.condition == '>'
      end

      # Max gem version which satisfies this dependency
      #
      # Can't automatically deduce in '<' case, so if that is the conditional
      # we require a version list, and will return the gcd from it
      def max_satisfying_version(versions=nil)
        return Float::INFINITY if self.version.nil?      ||
                                  self.condition == '>'  ||
                                  self.condition == '>='
        return self.version    if self.condition == '='  ||
                                  self.condition == '<='

        raise ArgumentError    if versions.nil?
        self.gcd(versions)
      end

      # Minimum gem version for which this dependency fails
      def min_failing_version
        raise ArgumentError if self.version.nil?
        return "0.0"        if self.condition == '>'  ||
                               self.condition == '>='
        return self.version if self.condition == '<'
        Versionomy.parse(self.version).bump(:tiny).to_s # self.condition == '<=' and '='
      end

      # Max gem version for which this dependency fails
      #
      # Can't automatically deduce in '>=', and '=' cases, so if that is the
      # conditional we require a version list, and will return the gcd from it
      def max_failing_version(versions=nil)
        raise ArgumentError if self.version.nil?      ||
                               self.condition == '<=' ||
                               self.condition == '<'
        return self.version if self.condition == '>'

        raise ArgumentError if versions.nil?
        self.gcd(versions)
      end

      def matches?(dep)
        return self == dep      if dep.is_a?(self.class)
        raise ArgumentError unless dep.is_a?(::Gem::Dependency)

        return false if !self.gem? || self.gem_name != dep.name
        return true  if  self.version.nil?

        Gem2Rpm::Helpers.expand_requirement([dep.requirement.to_s.split]).
          any?{ |req|
            req.first == self.condition && req.last.to_s == self.version
          }
      end

      def gem?
        !!(self.str =~ RPM::Spec::SPEC_GEM_REQ_MATCHER)
      end

      def gem_name
        # XXX need to explicitly run regex here to get $1
        !!(self.str =~ RPM::Spec::SPEC_GEM_REQ_MATCHER) ? $1 : nil
      end
    end # class Requirement
  end # module RPM 
end
