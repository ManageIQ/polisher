#!/usr/bin/ruby
# binary gem resolver
#
# Looks up missing binary dependencies required by ruby packages via
# various backends (currently yum, more to be added)
#
# gem install packages as normal. If any fail due to missing requirements,
# run this script w/ the location of the failed install like so:
#
# ./binary_gem_resolver.rb <path-to-gem-install>
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.
###########################################################

require 'polisher/cli/all'
require 'polisher/cli/bin/binary_gem_resolver'

include Polisher::CLI

parse_args
verify_args!

# require the gem's extconf
require extconf
