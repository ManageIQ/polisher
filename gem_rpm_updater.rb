#!/usr/bin/ruby
# gem rpm updater
#
# Will checkout an existing gem rpm from fedora,
# and update to the latest version found on http://rubygems.org
#
# Usage: 
#   gem_rpm_updater.rb <gem_name>
#
# Licensed under the MIT License
# Copyright (C) 2013 Red Hat, Inc.

require 'colored'
require 'curb'
require 'json'
require 'optparse'
require 'nokogiri'

#######################################################3

# read package/user name from command line
user = nil
gems = []
optparse = OptionParser.new do|opts|
  opts.on('-n', '--name GEM', 'gem name' ) do |n|
    gems << n
  end
  opts.on('-u', '--user USER', 'fedora user name' ) do |u|
    user = u
  end
  opts.on('-h', '--help', 'display this screen' ) do
    puts opts
    exit
  end
end
optparse.parse!

unless user.nil?
  curl = Curl::Easy.new("https://admin.fedoraproject.org/pkgdb/users/packages/#{user}")
  curl.http_get
  packages = curl.body_str
  gems += Nokogiri::HTML(packages).xpath("//a[@class='PackageName']").
                                   select { |i| i.text =~ /rubygem-.*/ }.
                                   collect { |i| i.text.gsub(/rubygem-/, '') }
end

if gems.empty?
  puts "must specify a gem name or fedora user name!".red
  exit 1
end

orig_dir = Dir.pwd

gems.each { |gem_name|
  puts "Updating #{gem_name}".bold.green
  Dir.chdir orig_dir

  # TODO allow specifying version to update to as 2nd argument
  
  rpm_name = "rubygem-#{gem_name}"
  
  # assumes fedpkg is present
  # TODO detect if directory exists, if so skip checkout (perhaps just pull?)
  # TODO at some point use fedora api
  unless File.directory? rpm_name
    puts "Cloning fedora package".green
    `fedpkg clone #{rpm_name}`
  end
  
  # cd into working directory
  Dir.chdir rpm_name

  if File.exists? 'dead.package'
    puts "Dead package detected, skipping".red
    next 
  end
  
  # checkout the latest rawhide
  # TODO allow other branches to be specified
  `git checkout master`
  `git reset HEAD~ --hard` # BE CAREFUL!
  `git pull`
  
  # grab the gem from rubygems
  puts "Grabbing gem".green
  spec  = Curl::Easy.http_get("https://rubygems.org/api/v1/gems/#{gem_name}.json").body_str
  specj = JSON.parse(spec)
  
  # extract version out of it
  version = specj["version"]
  
  # download gem
  puts "Downloading #{gem_name}-#{version}.gem".green
  curl = Curl::Easy.new("https://rubygems.org/gems/#{gem_name}-#{version}.gem")
  curl.follow_location = true
  curl.http_get
  gem = curl.body_str
  File.open("#{gem_name}-#{version}.gem", "w") { |f| f.write gem }
  
  # substitute version in spec file
  puts "Updating spec file to version #{version}".green
  `sed -i "s/Version.*/Version: #{version}/" #{rpm_name}.spec`
  `sed -i "s/^Release.*/Release: 1%{?dist}/" #{rpm_name}.spec`
  
  # build srpm
  puts "Building srpm".green
  `fedpkg srpm`
  
  # attempt to build packages against rawhide w/ koji
  puts "Building srpm in rawhide via koji".green
  puts "koji build --scratch rawhide #{rpm_name}-#{version}-1.*.src.rpm".green
  puts `koji build --scratch rawhide #{rpm_name}-#{version}-1.*.src.rpm`.blue
  
  # TODO if build fails, spit out error, exit
  
  # warn user if tests are not run (no check section)
  has_check = open("#{rpm_name}.spec", "r") { |f| f.lines.find { |line| line.include?("%check") } }
  puts "Warning: no %check section in spec, manually verify functionality!".bold.red unless has_check
  
  # update sources and gitignore files
  `md5sum #{gem_name}-#{version}.gem > sources`
  File.open(".gitignore", "w") { |f| f.write "#{gem_name}-#{version}.gem" }
  
  # TODO also need to add a spec changelog message
  
  # git add spec, git commit w/ message
  `git add #{rpm_name}.spec sources .gitignore`
  #`git add #{gem_name}-#{version}.gem`
  `git commit -m 'updated to #{version}'`
  
  # spit out command to push the package to fedora,
  # build it against koji, and submit it to bodhi
  puts "#{gem_name} commit complete".green
}
puts "Push commit to fedora with: git push".blue
puts "Build and tag official rpms with: koji build".blue
#puts "Submit updates via: https://admin.fedoraproject.org/updates".blue # uneeded for rawhide
