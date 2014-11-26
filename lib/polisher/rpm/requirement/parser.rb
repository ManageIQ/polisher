# Polisher RPM Requirement Parser Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module RPM
    module RequirementParser
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Instantiate / return new rpm spec requirements from string
        def parse(str, opts = {})
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

          req = new({:name      => name,
                     :condition => condition,
                     :version   => version,
                     :br        => br}.merge(opts))
          req
        end
      end # module ClassMethods
    end # module RequirementParser
  end # module RPM
end # module Polisher
