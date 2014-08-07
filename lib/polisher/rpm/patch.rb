# Polisher RPM Patch Representation
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

module Polisher
  module RPM
    class Patch
      attr_accessor :title
      attr_accessor :content

      def initialize(args = {})
        @title   = args[:title]
        @content = args[:content]
      end

      def spec_line(n = 0)
        "Patch#{n}: #{title}"
      end

      def self.from(diff)
        return diff.collect { |d| from(d) } if diff.is_a?(Array)

        result = {}

        in_diff = nil
        diff.each_line do |line|
          if line =~ /diff -r ([^\s]+)+ ([^\s]+)+$/
            result[in_diff] = diff if in_diff
            in_diff = $1.gsub(/a\//, '')
            diff    = ''
          elsif line =~ /Only in.*$/
            in_diff = nil

          else
            diff += line
          end
        end

        result.collect { |t, c| new :title => t, :content => c }
      end
    end
  end
end
