#!/usr/bin/ruby
# Get/set polisher config options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'optparse'
require 'colored'
require 'polisher/util/config'

Polisher::Config.set
Polisher::Config::target_classes.each { |tc|
  tc.conf_attrs.each { |attr|
    puts "#{tc} #{attr} = #{tc.send(attr)}"
  } if tc.conf_attrs?
}
