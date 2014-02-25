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

require 'colored'
require 'curb'
require 'json'
require 'optparse'
require 'nokogiri'

require 'polisher/git'
require 'polisher/gem'

ORIG_DIR = Dir.pwd

# read various options from the command line
conf = { :dir            => ORIG_DIR,
         :user           => nil,
         :gems           =>  []}
 
optparse = OptionParser.new do|opts|
  opts.on('-n', '--name GEM', 'gem name' ) do |n|
    conf[:gems] << n
  end

  opts.on('-u', '--user USER', 'fedora user name' ) do |u|
    conf[:user] = u
  end

  opts.on('-d', '--dir path', 'Directory to cd to before checking out / manipulating packages' ) do |p|
    conf[:dir] = p
  end

  opts.on('-h', '--help', 'display this screen' ) do
    puts opts
    exit
  end
end
 
 optparse.parse!

conf[:gems] += Polisher::Fedora.gems_owned_by(conf[:user]) unless conf[:user].nil?

if conf[:gems].empty?
  puts "must specify a gem name or user name!".red
  exit 1
end

Dir.mkdir conf[:dir] unless File.directory?(conf[:dir])
Dir.chdir conf[:dir]

# iterate over gems
conf[:gems].each do |gem_name|
  pkg =
    begin
      Polisher::Git::Package.new(:name => gem_name).clone
    rescue => e
      puts "Problem Cloning Package, Skipping: #{e}"
      next
    end

  gem = Polisher::Gem.retrieve gem_name
  File.write("#{gem.name}-#{gem.version}.gem", gem.download_gem)
  pkg.update_to(gem)
  # TODO append gem dependencies to conf[:gems] list

  pkg.build

  unless pkg.spec.has_check?
    puts "Warning: no %check section in spec, "\
         "manually verify functionality!".bold.red
  end

  pkg.commit

  puts "#{gem_name} commit complete".green
  puts "Push commit with: git push".blue
  puts "Build and tag official rpms with: #{Polisher::Git::Package.pkg_cmd} build".blue
end
