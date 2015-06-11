#!/usr/bin/ruby
# Polisher CLI Gem Specifier Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'polisher/specifier'

module Polisher
  module CLI
    def specifier_conf
      { :matching   => LATEST_SPECIFIER }
    end

    def specifier_opts(option_parser)
      option_parser.on('--latest', 'Check latest matching version of gem') do
        conf[:matching] = LATEST_SPECIFIER
      end

      option_parser.on('--earliest', 'Check earliest matching version of gem') do
        conf[:matching] = EARLIEST_SPECIFIER
      end

      option_parser.on('--target [tgt]', 'Check version of gem in target') do |t|
        conf[:matching] = t
      end
    end
  end # module CLI
end # module Polisher
