#!/usr/bin/ruby
# Gem Dependency Checker
# Print out Gem/Gemspec/Gemfile dependencies, highlighting
# missing dependencies and those that are remotely
# available in various locations including koji,
# git, fedora, bodhi, rhn, etc.
#
# Pass -h to the script to see command line option details
#
# User is responsible for establishing authorization session
# before invoking this script
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.
###########################################################

require 'optparse'
require 'colored'

require 'polisher/gem'
require 'polisher/gemfile'
require 'polisher/util/config'

require 'polisher/cli/all'

include Polisher::CLI

##########################################################

def gem_dependency_checker_conf
  conf.merge!({:format => nil}).merge!(default_conf)
                               .merge!(targets_conf)
                               .merge!(sources_conf)
end

def gem_dependency_checker_options(option_parser)
  option_parser.on("--format val", 'Format which to render output') do |f|
    conf[:format] = f
  end
end

def gem_dependency_checker_option_parser
  OptionParser.new do |opts|
    default_options                opts
    sources_options                opts
    targets_options                opts
    gem_dependency_checker_options opts
  end
end

def print_header
  if @format == 'xml'
    puts '<dependencies>'
  elsif @format == 'json'
    puts '{'
  end
end

def print_footer
  if @format == 'xml'
    puts "</dependencies>"
  elsif @format == 'json'
    puts "}"
  end
end

def print_dep(tgt, dep, versions)
  puts pretty_dep(tgt, dep, versions)
end

def print_gem_deps(conf)
  gem = conf[:gemversion] ? Polisher::Gem.from_rubygems(conf[:gemname], conf[:gemversion]) :
                            Polisher::Gem.retrieve(conf[:gemname])
  gem.versions(:recursive => true,
               :dev_deps  => conf[:devel_deps]) do |tgt, dep, versions|
    print_dep(tgt, dep, versions)
  end
end

def print_gemspec_deps(conf)
  gem = Polisher::Gem.from_gemspec(conf[:gemspec])
  gem.versions(:recursive => true,
               :dev_deps  => conf[:devel_deps]) do |tgt, dep, versions|
    print_dep(tgt, dep, versions)
  end
end

def print_gemfile_deps(conf)
  gemfile = nil

  begin
    gemfile = Polisher::Gemfile.parse(conf[:gemfile], :groups => conf[:groups])
  rescue => e
    puts "Runtime err #{e}".red
    exit 1
  end

  gemfile.dependency_versions :recursive => true,
                              :dev_deps  => conf[:devel_deps] do |tgt, dep, versions|
    print_dep(tgt, dep, versions)
  end
end

def print_deps(conf)
  if conf[:gemname]
    print_gem_deps(conf)
  
  elsif conf[:gemspec]
    print_gemspec_deps(conf)
  
  elsif conf[:gemfile]
    print_gemfile_deps(conf)
  end

  puts last_dep # XXX
end

##########################################################

conf = gem_dependency_checker_conf
optparse = gem_dependency_checker_option_parser
optparse.parse!
validate_sources

Polisher::Logging.level = conf[:log_level]
Polisher::Config.set
set_targets       conf
configure_targets conf
set_format        conf
print_header
print_deps        conf
print_footer
