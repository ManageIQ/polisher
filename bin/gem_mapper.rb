#!/usr/bin/ruby
# Gem Dependency Mapper
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'optparse'
require 'colored'

require 'polisher/gemfile'

require 'polisher/cli/all'
require 'polisher/util/logger'
require 'polisher/util/config'

include Polisher::CLI

def gem_mapper_conf
  conf.merge!(default_conf)
      .merge!(specifier_conf)
      .merge!(sources_conf)
end

def gem_mapper_parser
  optparse = OptionParser.new do |opts|
    default_options(opts)
    sources_options(opts)
     specifier_opts(opts)
  end
end

def print_dep(gem, dep)
  puts pretty_dep(gem, dep)
end

def print_gem_deps(gem)
  gem.dependency_tree(:recursive => true,
                      :dev_deps  => conf[:devel_deps],
                      :matching  => conf[:matching]) do |gem, dep|
    print_dep(gem, dep)
  end
end

def print_gemfile_deps(gemfile)
  gemfile.dependency_tree(:recursive => true,
                          :dev_deps  => conf[:devel_deps],
                          :matching  => conf[:matching]) do |gem, dep|
    print_dep(gem, dep)
  end
end

def print_tree(conf)
  if conf_gem?
    print_gem_deps(conf_source)
  
  elsif conf_gemfile?
    print_gemfile_deps(conf_source)

  end

  # XXX
  puts last_dep
  puts last_gem
end

    conf = gem_mapper_conf
optparse = gem_mapper_parser
optparse.parse!

validate_sources

Polisher::Logging.level = conf[:log_level]
Polisher::Config.set
print_tree conf
