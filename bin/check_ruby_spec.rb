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
# Copyright (C) 2013 Red Hat, Inc.

require 'colored'
require 'polisher'

spec_file = ARGV.shift
source    = ARGV.shift
rpmspec   = Polisher::RPMSpec.parse File.read(spec_file)
source    = source.nil? ?
  Polisher::Gem.retrieve(rpmspec.gem_name) :
  Polisher::Upstream.parse(source)

result = rpmspec.compare(source)
unless result[:diff].keys.empty?
  puts "differences between rpmspec and upstream source detected".red.bold
  result[:diff].each do |dep,versions|
    puts "#{dep} / " \
         "spec (#{versions[:spec]}) / " \
         "upstream #{versions[:upstream]}".bold.red
  end
end
