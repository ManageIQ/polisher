# Polisher RPM Requirement
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/conf_helpers'
require 'polisher/rpm/requirement/attributes'
require 'polisher/rpm/requirement/parser'
require 'polisher/rpm/requirement/comparison'
require 'polisher/rpm/requirement/gem_reference'

module Polisher
  module RPM
    class Requirement
      include ConfHelpers
      include RequirementAttributes
      include RequirementParser
      include RequirementComparison

      # TODO: make this mixin optional depending on if requirement corresponds to gem
      include RequirementGemReference

      conf_attr :rubygem_prefix, :default => 'rubygem'
      conf_attr :scl_prefix,     :default => '' # set to %{?scl_prefix} to enable scl's

      def initialize(args = {})
        @br        = args[:br] || false
        @name      = args[:name]
        @condition = args[:condition]
        @version   = args[:version]
        @name.strip!      unless @name.nil?
        @condition.strip! unless @condition.nil?
        @version.strip!   unless @version.nil?
      end
    end # class Requirement
  end # module RPM
end # module Polisher
