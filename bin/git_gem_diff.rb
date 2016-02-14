#!/usr/bin/ruby
# Diff a Git Gem Against its Rubygems equivalent
#
# ./git_gem_diff.rb
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.
###########################################################

require 'polisher/cli/all'
require 'polisher/cli/bin/git_gem_diff'

include Polisher::CLI

    conf = git_gem_diff_conf
optparse = git_gem_diff_option_parser
optparse.parse!

validate_args!
puts diff
