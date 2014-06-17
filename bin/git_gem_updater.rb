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
require 'optparse'

require 'polisher/git'
require 'polisher/gem'
require 'polisher/core'

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

Polisher::Config.set

unless conf[:user].nil?
  begin
    conf[:gems] += Polisher::Fedora.gems_owned_by(conf[:user])
  rescue
    puts "Could not retrieve gems owned by #{conf[:user]}".red
    exit 1
  end
end

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
      Polisher::Git::Pkg.new(:name => gem_name).fetch
    rescue => e
      puts "Problem Cloning Package, Skipping: #{e}"
      next
    end

  gem = Polisher::Gem.retrieve gem_name
  pkg.update_to(gem)
  # TODO append gem dependencies to conf[:gems] list

  begin
    pkg.build
  rescue => e
    puts "Warning: scratch build failed: #{e}".bold.red
  end

  unless pkg.spec.has_check?
    puts "Warning: no %check section in spec, "\
         "manually verify functionality!".bold.red
  end

  pkg.commit

  puts "#{gem_name} commit complete".green
  puts "Package located in #{pkg.path.bold}"
  puts "Push commit with: git push".blue
  puts "Build and tag official rpms with: #{Polisher::Git::Pkg.pkg_cmd} build".blue
end
