#!/usr/bin/ruby
# Display missing deps
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'polisher/util/logger'
require 'polisher/util/config'

require 'polisher/cli/all'
require 'polisher/cli/bin/missing_deps'

include Polisher::CLI

    conf = missing_deps_conf
optparse = missing_deps_parser
optparse.parse!

validate_sources

Polisher::Logging.level = conf[:log_level]
Polisher::Config.set
set_targets       conf
configure_targets conf
begin
check_deps conf
rescue Exception => e
end
