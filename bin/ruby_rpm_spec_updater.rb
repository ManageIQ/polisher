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

spec_file = ARGV.shift
source    = ARGV.shift
rpmspec   = Polisher::RPMSpec.parse File.read(spec_file)
source    = source.nil? ?
  Polisher::Gem.retrieve(rpmspec.gem_name) :
  Polisher::Upstream.parse(source)

rpmspec.update_to(source)
puts rpmspec.to_string
