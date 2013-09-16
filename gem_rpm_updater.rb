#!/usr/bin/ruby
# gem rpm updater
#
# Will checkout an existing gem rpm from distgit,
# and update to the latest version found on http://rubygems.org
#
# Usage: 
#   gem_rpm_updater.rb -n <gem_name>
#
# Licensed under the MIT License
# Copyright (C) 2013 Red Hat, Inc.

require 'colored'
require 'curb'
require 'json'
require 'optparse'
require 'nokogiri'

ORIG_DIR = Dir.pwd

#######################################################

# read various options from the command line
def parse_options
  $conf = { :dir            => ORIG_DIR,
            :user           => nil,
            :gems           =>  [],
            :package_list   =>
                'https://admin.fedoraproject.org/pkgdb/users/packages/',
            :pkg_command    => '/usr/bin/fedpkg',
            :git_command    => '/usr/bin/git',
            :sed_command    => '/usr/bin/sed',
            :md5sum_command => '/usr/bin/md5sum',
            :build_command   => '/usr/bin/koji',
            :build_target   => 'rawhide'}
  
  optparse = OptionParser.new do|opts|
    opts.on('-n', '--name GEM', 'gem name' ) do |n|
      $conf[:gems] << n
    end
  
    opts.on('-u', '--user USER', 'fedora user name' ) do |u|
      $conf[:user] = u
    end

    opts.on('-d', '--dir path', 'Directory to cd to before checking out / manipulating packages' ) do |p|
      $conf[:dir] = p
    end
  
    opts.on('-p', '--package-list location',
            'Location which to retreive list of gems to update' ) do |l|
      $conf[:package_list] = l
    end
  
    opts.on('-c', '--pkg-command cmd',
            'Command to use to perform package operations' ) do |c|
      $conf[:pkg_command] = c
    end

    opts.on('-b', '--build-command cmd',
            'Command to use to build packages' ) do |c|
      $conf[:build_command] = c
    end

    opts.on('-t', '--build-target target',
            'Target to build packages against' ) do |t|
      $conf[:build_target] = t
    end
  
    opts.on('-h', '--help', 'display this screen' ) do
      puts opts
      exit
    end
  end
  
  optparse.parse!
end

# retrieve gems a user maintains from fedora
def load_user_gems
  curl = Curl::Easy.new("#{$conf[:package_list]}#{$conf[:user]}")
  curl.http_get
  packages = curl.body_str
  gems += Nokogiri::HTML(packages).xpath("//a[@class='PackageName']").
                                   select { |i| i.text =~ /rubygem-.*/ }.
                                   collect { |i| i.text.gsub(/rubygem-/, '') }
end

# retrieve the existing gem package
def download_gem_package(rpm_name)
  puts "Updating #{rpm_name}".bold.green
  unless File.directory? rpm_name
    puts "Cloning fedora package".green
    `#{$conf[:pkg_command]} clone #{rpm_name}`
  end
  
  # cd into working directory
  Dir.chdir rpm_name

  if File.exists? 'dead.package'
    puts "Dead package detected, skipping".red
    return false
  end
  
  # checkout the latest rawhide
  # TODO allow other branches to be specified
  `#{$conf[:git_command]} checkout master`
  `#{$conf[:git_command]} reset HEAD~ --hard` # BE CAREFUL!
  `#{$conf[:git_command]} pull`
  
  true
end

# retrieve gem from rubygems.org
def download_gem(gem_name)
  # grab the gem from rubygems
  puts "Grabbing gem".green
  gem_path = "https://rubygems.org/api/v1/gems/#{gem_name}.json"
  spec  = Curl::Easy.http_get(gem_path).body_str
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

  version
end

# update spec to new version
def update_spec(rpm_name, version)
  # substitute version in spec file
  puts "Updating spec file to version #{version}".green
  `#{$conf[:sed_command]} -i "s/Version.*/Version: #{version}/" #{rpm_name}.spec`
  `#{$conf[:sed_command]} -i "s/^Release.*/Release: 1%{?dist}/" #{rpm_name}.spec`
  # TODO also need to add a spec changelog message
end

# build the package
def build_package(rpm_name, version)
  # build srpm
  puts "Building srpm".green
  `#{$conf[:pkg_command]} srpm`
  
  # attempt to build packages
  puts "Building srpm in #{$conf[:build_target]} via #{$conf[:build_command]}".green
  puts "#{$conf[:build_command]} build --scratch #{$conf[:build_target]} \
        #{rpm_name}-#{version}-1.*.src.rpm".green
  puts `#{$conf[:build_command]} build --scratch #{$conf[:build_target]} \
        #{rpm_name}-#{version}-1.*.src.rpm`.blue
  # TODO if build fails, spit out error, exit
end

# check the %check section of the spec
def check_tests(rpm_name)
  # warn user if tests are not run (no check section)
  has_check = open("#{rpm_name}.spec", "r") { |f|
                f.lines.find { |line| line.include?("%check") }
              }
  puts "Warning: no %check section in spec,\
        manually verify functionality!".bold.red unless has_check
  
end

# update sources and gitignore files
def update_sources(gem_name, version)
  `#{$conf[:md5sum_command]} #{gem_name}-#{version}.gem > sources`
  File.open(".gitignore", "w") { |f| f.write "#{gem_name}-#{version}.gem" }
end

# commit changes to local branch / stage push
def commit_changes(rpm_name, version)
  # git add spec, git commit w/ message
  `#{$conf[:git_command]} add #{rpm_name}.spec sources .gitignore`
  #`git add #{gem_name}-#{version}.gem`
  `#{$conf[:git_command]} commit -m 'updated to #{version}'`
  
  # spit out command to push the package to fedora,
  # build it against koji, and submit it to bodhi
  puts "#{rpm_name} commit complete".green

  puts "Push commit with: git push".blue
  puts "Build and tag official rpms with: #{$conf[:pkg_command]} build".blue
end

##############################################################################
  
parse_options

load_user_gems unless $conf[:user].nil? || $conf[:package_list].nil?

if $conf[:gems].empty?
  puts "must specify a gem name or user name!".red
  exit 1
end

# iterate over gems
$conf[:gems].each { |gem_name|
  Dir.chdir $conf[:dir]
  rpm_name = "rubygem-#{gem_name}"
  next unless download_gem_package(rpm_name)
  version = download_gem(gem_name)
  # $conf[:gems] += download_deps(gem_name) # TODO
  update_spec(rpm_name, version)
  build_package(rpm_name, version)
  check_tests(rpm_name)
  update_sources(gem_name, version)
  commit_changes(rpm_name, version)
}
