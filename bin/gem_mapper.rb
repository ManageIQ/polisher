#!/usr/bin/ruby
# Gem Dependency Mapper
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'polisher/gemfile'
require 'polisher/util/config'

require 'polisher/cli/all'
require 'polisher/cli/bin/gem_mapper'

include Polisher::CLI

    conf = gem_mapper_conf
optparse = gem_mapper_parser
optparse.parse!

validate_sources

Polisher::Logging.level = conf[:log_level]
Polisher::Config.set
begin
print_tree conf
rescue Exception => e
puts "Err #{e} #{e.backtrace.join("\n")}"
end
