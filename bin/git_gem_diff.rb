#!/usr/bin/ruby
# Diff a Git Gem Against its Rubygems equivalent
#
# ./git_gem_diff.rb
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.
###########################################################

require 'colored'
require 'polisher/git/pkg'
require 'polisher/git/repo'

conf = { :git => nil}

optparse = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this help screen') do
    puts opts
    exit
  end

  opts.on('-g', '--git [url]', 'url') do |url|
    conf[:git] = url
  end
end

optparse.parse!

if conf[:git].nil?
  puts "Must specify a git url".bold.red
  exit 1
end

git = Polisher::Git::Repo.new :url => conf[:git]
git.clone unless git.cloned?

name, version = nil

git.in_repo do
  gemspec_path = Dir.glob('*.gemspec').first
  gem          = Polisher::Gem.from_gemspec gemspec_path
  name    = gem.name
  version = gem.version
end

gem = Polisher::Gem.from_rubygems name, version
diff = gem.diff(git)
puts diff
