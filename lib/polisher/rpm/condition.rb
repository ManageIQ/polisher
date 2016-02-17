# Polisher RPM Conditon (%if / %endif block
#
# Licensed under the MIT license
# Copyright (C) 2016 Red Hat, Inc.

module Polisher
  module RPM
    class Condition
      attr_accessor :str, :parent

      def initialize(args = {})
        @str    = args[:str]
        @parent = args[:parent]
      end
    end
  end # module RPM
end # module Polisher
