# Polisher Components & Component Helpers
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'active_support'
require 'active_support/core_ext'

module Polisher
  module Component
    class Missing
      def initialize(*args)
        raise "polisher is missing a dependency - cannot instantiate"
      end

      def method_missing(method_id, *args, &bl)
        raise "polisher is missing a dependency - cannot invoke #{method_id} on #{self}"
      end
    end # class MissingComponent

    def self.verify(polisher_klass, *dependencies)
      all_required = dependencies.all? do |dep|
        require_dependency(polisher_klass, dep)
      end

      yield if all_required
    end

    def self.require_dependency(polisher_klass, dependency)
      require dependency
      true
    rescue LoadError
      klasses = polisher_klass.split("::")
      desired_namespace = Polisher

      klasses.each do |k|
        desired_namespace.const_set(k, Missing) unless desired_namespace.const_defined?(k)
        desired_namespace = "#{desired_namespace.name}::#{k}".constantize
      end
      warn "Failed to require #{dependency}.  Added runtime exception in Polisher::#{polisher_klass}"
    end
  end # module Component
end # module Polisher
