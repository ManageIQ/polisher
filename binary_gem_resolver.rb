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
# Copyright (C) 2013 Red Hat, Inc.
###########################################################

require 'colored'

# retrieve extconf.rb for gem at specified path in filesystem
gem_dir = ARGV.shift
extconf = nil

require 'find'
Find.find(gem_dir) do |path|
  if path =~ /.*extconf.rb/
    extconf = File.expand_path path
    break
  end
end

if extconf.nil?
  puts "extconf could not be found".red.bold
  exit 1
end

# helper to lookup missing headers / print packages that satisfy them
def lookup_missing(header)
  puts 'looking up... (may take a few minutes)'.yellow
  matches = []
  `yum provides */usr/include/#{header}`.each_line { |l|
    if l =~ /(.*)\.fc.*/
      matches << $1
    end
  }
  puts "packages which provide header:\n#{matches.join("\n")}".yellow.bold
end

#############################################################

# require/override mkmf methods 
require 'mkmf'

alias :_cpp_command :cpp_command
def cpp_command(outfile="", opt)
  ""
end

alias :_have_library :have_library
def have_library(lib, func = nil, headers = nil, &b)
  _have_library(lib, func, headers, &b)
end

alias :_find_library :find_library
def find_library(lib, func, *paths, &b)
  _find_library(lib, func, *paths, &b)
end

alias :_have_func :have_func
def have_func(func, headers = nil, &b)
  _have_func(func, headers, &b)

  rescue => e
    puts "missing func #{func}".red.bold
end

alias :_hav_header :have_header
def have_header(header, preheaders = nil, &b)
  _have_header(header, preheaders, &b)

  rescue => e
    puts "missing header #{header}".red.bold
    lookup_missing(header)
end

# other mkmf methods which may be overridden
#def find_header(header, *paths)
#def have_var(var, headers = nil, &b)
#def try_type(type, headers = nil, opt = "", &b)
#def have_type(type, headers = nil, opt = "", &b)
#def find_type(type, opt, *headers, &b)
#def try_const(const, headers = nil, opt = "", &b)
#def have_const(const, headers = nil, opt = "", &b)
#def find_executable0(bin, path = nil)

# require the gem's extconf
require extconf
