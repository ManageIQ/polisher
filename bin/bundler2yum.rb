#!/usr/bin/ruby
# Tool to convert a bundler Gemfile + various
# RPM sources to a yum repository
#
# Pass -h to command for complete list of command
# line options
#
# Licensed under the MIT License
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'colored'
require 'optparse'

conf = { :gemfile => './Gemfile',
         :sources => [],
         :dest    => nil}

optparse = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this help screen') do
    puts opts
    exit
  end

  opts.on('--gemfile file', 'Location of the gemfile to parse') do |g|
    conf[:gemfile] = g
  end

  opts.on('--source source', 'Source which to pull packages from') do |s|
    conf[:sources] << s
  end

  opts.on('--dest dest', 'Destination which to write repo to') do |s|
    conf[:dest] = nil
  end
end

optparse.parse!

if conf[:gemfile].nil? || conf[:dest].nil?
  puts "Valid Gemfile must be specified".bold.red
  exit 1
end

gemfile = Polisher::Gemfile.parse(conf[:gemfile])
gemfile.dependency_versions do |tgt, dep, versions|
  # TODO:
  # - attempt to retrieve versioned dependency from specified sources
  # - error out if package cannot be retrieved
  # - use createrepo and/or other tool (should be configurable)
  #   to create yum (or other) repo
end
