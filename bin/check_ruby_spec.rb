#!/usr/bin/ruby
# Check a Ruby RPM spec against an upstream source
#   to validate it is up to date
#
# Run with the path to the spec to validate along
# with optional upstream source
#
# Usage:
#   check_ruby_spec.rb <path-to-spec> <optional-source-or-version>
#
# Licensed under the MIT License
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/cli/all'
require 'polisher/cli/bin/check_ruby_spec'

include Polisher::CLI

parse_args
validate_args!
run_check
