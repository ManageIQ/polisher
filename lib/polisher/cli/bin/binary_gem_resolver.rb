# Polisher binary_gem_resolver cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'find'
require 'colored'

def parse_args
  conf[:gem_dir] = ARGV.shift
end

def gem_dir
  conf[:gem_dir]
end

def gem_dir?
  !!gem_dir
end

def extconf
  @extconf ||= begin
    # retrieve extconf.rb for gem at specified path in filesystem
    ec = nil
    Find.find(gem_dir) do |path|
      if path =~ /.*\/extconf.rb$/
        ec = File.expand_path path
        break
      end
    end

    ec
  end
end

def verify_args!
  return if gem_dir && !extconf.nil?
  puts "extconf could not be found".red.bold
  exit 1
end

# processed components
def processed
  @processed ||= []
end

# Print message for missing components not already processed
def fail_message(component, lookup)
  return false if processed.include?(component)
  processed << component
  puts "missing #{component}".bold.red
  puts "looking up #{lookup}".bold.blue
  return true
end

def sanitize_paths(paths)
  paths.collect { |path|
    path.gsub("local",      "")
        .gsub(/\/\/+/,      "/")
        .gsub("/usr/lib/",  "")
        .gsub("/usr/lib64", "")
        .gsub(/\/\/+/,      "/")
  }.reject { |path| path == "" }.compact
end

# Return packages providing specified component
def packages_providing(component)
  matches = []
  `yum provides #{component}`.each_line { |l|
    matches << $1 if l =~ /(.*)\.fc.*/
  }
  matches
end

# Return packages providing specified header
def packages_providing_header(header)
  packages_providing("*/usr/include/#{header}")
end

# Return packages providing specified library
def packages_providing_library(library, *paths)
  packages_providing("*/usr/lib/lib#{library}.so.*") +
  packages_providing("*/usr/lib64/lib#{library}.so.*") +
  paths.collect { |path|
    packages_providing("*/usr/lib#{path}/lib#{library}.so.*") +
    packages_providing("*/usr/lib64#{path}/lib#{library}.so.*")
  }.flatten
end

# Lookup missing headers / print packages that satisfy them
def lookup_header(args)
  header  = args[:header]
  matches = packages_providing_header(header).join("\n")
  puts "packages which provide header:\n#{matches}".bold.blue
end

# Lookup missing libraries / print packages that satisfy them
def lookup_library(args)
  library = args[:library]
  paths   = args.key?(:paths) ? sanitize_paths(args[:paths]) : []
  matches = packages_providing_library(library, *paths).join("\n")
  puts "packages which provide library:\n#{matches}".bold.blue
end

# Lookup missing executable / print packages that satify if
def lookup_executable(args)
  executable = args[:executable]
  matches    = packages_providing("*#{executable}").join("\n")
  puts "packages which provide executable:\n#{matches}".bold.blue
end

# Lookup missing component
def lookup(args={})
  return unless fail_message args[:component],
                             args[:header]  ||
                             args[:library] ||
                             args[:executable]
  lookup_header     args     if args.key?(:header)
  lookup_library    args    if args.key?(:library)
  lookup_executable args    if args.key?(:executable)
end

#############################################################

# overridden mkmf methods
require 'mkmf'

# TODO find a way to lookup c-macros via library / pkg system
#alias :_have_macro :have_macro
#def have_macro(macro, headers = nil, opt = "", &b)
#  _have_macro(macro, headers, opt, &b)
#end

alias :_have_library :have_library
def have_library(lib, func = nil, headers = nil, &b)
  success = _have_library(lib, func, headers, &b)
  lookup :component => "#{lib}##{func}",
         :library   => lib                unless success
  success
end

alias :_find_library :find_library
def find_library(lib, func, *paths, &b)
  success = _find_library(lib, func, *paths, &b)
  lookup :component => "#{lib}##{func}",
         :library   => lib,
         :paths     => paths               unless success
  success
end

# TODO find a way to lookup c-functions via library / pkg system
#alias :_have_func :have_func
#def have_func(func, headers = nil, &b)
#  success = _have_func(func, headers, &b)
#  fail_message "#{func}" unless success
#  success
#end

# TODO find a way to lookup c-global-variables via library / pkg system
#alias :_have_var :have_var
#def have_var(var, headers = nil, opt = "", &b)
#  success = _have_var(var, headers, opt, &b)
#end

alias :_have_header :have_header
def have_header(header, preheaders = nil, &b)
  success = _have_header(header, preheaders, &b)
  lookup :component => "#{lib}##{func}",
         :header    => header              unless success
  success
end

# TODO find a way to lookup c-frameworks via library / pkg system
#      see mkmf.rb for definition of framework
#alias :_have_framework :have_framework
#def have_framework(fw)
#puts "HF"
#  _have_framework(fw)
#end

# TODO mechanism to lookup c-struct-members via library / pkg system
#alias :_have_struct_member :have_struct_member
#def have_struct_member(type, member, headers = nil, opt = "", &b)
#puts "HSM"
#  _have_struct_member(type, member, headers, opt, &b)
#end

# TODO mechanism to lookup c-types via library / pkg system
#alias :_have_type :have_type
#def have_type(type, headers = nil, opt = "", &b)
#puts "HT"
#  _have_type(type, headers, opt, &b)
#end

# TODO mechanism to lookup c-types via library / pkg system
#alias :_find_type :find_type
#def find_type(type, opt, *headers, &b)
#puts "FT"
#  _find_type(type, opts, *headers, &b)
#end

# TODO mechanism to lookup c-consts via library / pkg system
#alias :_have_const :have_const
#def have_const(const, headers = nil, opt = "", &b)
#puts "HC"
#  _have_const(const, headers, opt, &b)
#end

alias :_find_executable :find_executable
def find_executable(bin, path = nil)
  success = _find_executable(bin, path)
  lookup :component  => bin,
         :executable => bin  unless success
  success
end

