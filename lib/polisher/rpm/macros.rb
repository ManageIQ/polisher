# RPM Macro Collection
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.

require 'polisher/rpm/macro'

module Polisher
  module RPM
    class Macros < Array
      def expand(str)
        each { |macro| str = Macro.expand str }
        str
      end
    end # class Macros
  end # module RPM
end # module Polisher
