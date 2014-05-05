# Polisher Components & Component Helpers
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

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
      dependencies.each { |dep| require dep }
    rescue LoadError
      klass = polisher_klass.demodulize
      polisher_module = "Polisher::#{polisher_klass.deconstantize}"
      polisher_module.constantize.const_set(klass, Missing)
    else
      yield
    end
  end # module Component
end # module Polisher
