#!/usr/bin/ruby
# Enhanced gem updater that navigates the gem dependency tree
# and updates gems to their latest target versions
#
# Licensed under the MIT license
# Copyright (C) 2016 Red Hat, Inc.

require 'polisher/util/logger'
require 'polisher/util/config'

require 'polisher/cli/all'
require 'polisher/cli/bin/update_gems'

include Polisher::CLI

    conf = update_gems_conf
optparse = update_gems_parser
optparse.parse!

Polisher::Logging.level = conf[:log_level]
Polisher::Config.set
set_profiles conf

#begin
run_gems_update conf
#rescue Exception => e
#end
