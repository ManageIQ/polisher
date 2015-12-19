#!/usr/bin/ruby
# Polisher CLI Profile Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'polisher/util/profile'

module Polisher
  module CLI
    def profiles_conf
      { :profiles => [] }
    end

    def profiles_options(option_parser)
      option_parser.on('--profile [profile]', 'configuration profile to use') do |profile|
        conf[:profiles] << profile
      end
    end

    def set_profiles(conf)
      Profile.profiles conf[:profiles]
    end
  end # module CLI
end # module Polisher
