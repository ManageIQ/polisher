#!/usr/bin/ruby
# Display consolidated gems needing updating
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.

require 'polisher/util/logger'
require 'polisher/util/config'

require 'polisher/cli/all'
require 'polisher/cli/bin/gems2update'

include Polisher::CLI

    conf = gems2update_conf
optparse = gems2update_parser
optparse.parse!

Polisher::Logging.level = conf[:log_level]
Polisher::Config.set
set_targets       conf
set_profiles      conf
configure_targets conf

begin
check_gems conf
rescue Exception => e
end
