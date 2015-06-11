#!/usr/bin/ruby
# Gem Dependency Checker
# Print out Gem/Gemspec/Gemfile dependencies, highlighting
# missing dependencies and those that are remotely
# available in various locations including koji,
# git, fedora, bodhi, rhn, etc.
#
# Pass -h to the script to see command line option details
#
# User is responsible for establishing authorization session
# before invoking this script
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.
###########################################################

require 'polisher/gem'
require 'polisher/gemfile'
require 'polisher/util/config'

require 'polisher/cli/all'
require 'polisher/cli/bin/gem_dependency_checker'

include Polisher::CLI

    conf = gem_dependency_checker_conf
optparse = gem_dependency_checker_option_parser
optparse.parse!
validate_sources

Polisher::Logging.level = conf[:log_level]
Polisher::Config.set
set_targets       conf
configure_targets conf
set_format        conf
print_header
begin
print_deps        conf
rescue Exception
end
print_footer
