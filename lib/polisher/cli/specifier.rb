#!/usr/bin/ruby
# Polisher CLI Gem Specifier Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def specifier_conf
      { :matching   => :latest }
    end

    def specifier_opts(option_parser)
      option_parser.on('--latest', 'Check latest matching version of gem') do
        conf[:matching] = :latest
      end

      option_parser.on('--earliest', 'Check earliest matching version of gem') do
        conf[:matching] = :earliest
      end

      option_parser.on('--target [tgt]', 'Check version of gem in target') do |t|
        conf[:matching] = t
      end
    end
  end # module CLI
end # module Polisher
