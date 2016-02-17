#!/usr/bin/ruby
# Polisher CLI Fedora Utils
#
# Licensed under the MIT license
# Copyright (C) 2016 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def fedora_conf
      {:user => nil}
    end

    def fedora_options(option_parser)
      option_parser.on('-u', '--user USER', 'fedora user name' ) do |u|
        conf[:user] = u
      end
    end

    def user_gems
      return [] if conf[:user].nil?
      begin
        Polisher::Fedora.gems_owned_by(conf[:user])
      rescue
        puts "Could not retrieve gems owned by #{conf[:user]}".red
        exit 1
      end
    end
  end # module CLI
end # module Polisher
