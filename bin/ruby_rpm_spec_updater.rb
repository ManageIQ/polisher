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

conf = {}

optparse = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this help screen') do
    puts opts
    exit 0
  end

  opts.on('-i', 'In-place update of the spec file') do
    conf[:in_place] = true
  end
end

optparse.parse!

spec_file = ARGV.shift
source    = ARGV.shift

rpmspec   = Polisher::RPM::Spec.parse File.read(spec_file)
source    = source.nil? ?
  Polisher::Gem.retrieve(rpmspec.gem_name) :
  Polisher::Upstream.parse(source)

rpmspec.update_to(source)

if conf[:in_place]
  File.open(spec_file, "w") { |file| file.puts rpmspec.to_string }
else
  puts rpmspec.to_string
end
