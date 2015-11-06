# RPM Macro Representation
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.

require 'polisher/rpm/macro'

module Polisher
  module RPM
    class Macro
      DEFINE_MACRO_MATCHER = /^%define\s+([^\s]+)\s+(.+)$/
      GLOBAL_MACRO_MATCHER = /^%global\s+([^\s]+)\s+(.+)$/

      MACRO_USE_MATCHER    = /^[^%]*%\{([^\}]+)\}(.*)/

      attr_accessor :label
      attr_accessor :value

      def self.specifier?(str)
        str =~ DEFINE_MACRO_MATCHER || str =~ GLOBAL_MACRO_MATCHER
      end

      def self.from_specifier(str)
        return nil unless str =~ DEFINE_MACRO_MATCHER || str =~ GLOBAL_MACRO_MATCHER
        [$1, $2]
      end

      def self.parse(str)
        specifier = from_specifier str
        return nil if specifier.nil?
        macro = new
        macro.label = specifier.first
        macro.value = specifier.last
        macro
      end

      def self.included_in?(str)
        str =~ MACRO_USE_MATCHER
      end

      def self.extract_all(str)
        extracted = []
        while str =~ MACRO_USE_MATCHER
          extracted << $1
                 str = $2
        end
        extracted
      end

      def self.extract(str)
        extract_all(str).first
      end

      def self.replace_all(str, macros)
        extract_all(str).each do |extracted|
          str.gsub!("%{#{extracted}}", macros[extracted].value) if macros.key?(extracted)
        end
        str
      end

      def self.expand(str)
        str.gsub(macro.label, macro.value)
      end
    end # class Macro
  end # module RPM
end # module Polisher
