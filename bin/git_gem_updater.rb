#!/usr/bin/ruby
# git gem updater
#
# Will checkout an existing gem rpm from distgit,
# and update to the latest version found on http://rubygems.org
#
# Usage:
#   git_gem_updater.rb -n <gem_name>
#
# Licensed under the MIT License
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/config'
require 'polisher/cli/all'
require 'polisher/cli/bin/git_gem_updater'

include Polisher::CLI

conf = git_gem_updater_conf
optparse = git_gem_updater_option_parser
optparse.parse!
validate_gems!

Polisher::Config.set

chdir
update_gems
