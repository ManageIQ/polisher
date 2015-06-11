#!/usr/bin/ruby
# Polisher CLI Default Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def default_conf
      { :log_level => :info }
    end

    def default_options(option_parser)
      option_parser.on('-h', '--help', 'Display this help screen') do
        puts option_parser
        exit
      end

      option_parser.on('-l', '--log-level [level]', 'Set the log level') do |level|
        conf[:log_level] = level.intern
      end
    end
  end # module CLI
end # module Polisher
