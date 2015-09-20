#!/usr/bin/ruby
# Ruby RPM Spec Updater
#
# Simple tool to update the rpm spec of a packaged gem
# or ruby app.
#
# User should specify the location of the rpm spec to
# manipulate. Script takes an additional option to specify
# the version of the gem to update to or the location of
# the gem/gemspec/gemfile source which parse and use.
#
# Usage:
#   ruby_rpm_spec_updater.rb <path-to-spec> <optional-source-or-version>
#
# Licensed under the MIT License
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher'

require 'polisher/cli/all'
require 'polisher/cli/bin/ruby_rpm_spec_updater'

include Polisher::CLI

optparse = ruby_rpm_spec_updater_option_parser
optparse.parse!
parse_args
run_update!
