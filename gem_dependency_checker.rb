#!/usr/bin/ruby
# Gem Dependency Checker
# Print out Gem/Gemspec/Gemfile dependencies, highlighting
# missing dependencies and those that are remotely
# available in various locations including koji,
# git, fedora, bodhi, rhn, etc.
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.
###########################################################

require 'optparse'
require 'colored'
require 'pkgwat'
require 'tmpdir'
require 'git'
require 'xmlrpc/client'

XMLRPC::Config::ENABLE_NIL_PARSER = true

##########################################################

$conf = { :gemfile             => './Gemfile',
          :bundler             => false,
          :gemspec             => nil,
          :gemname             => nil,
          :gemversion          => nil,
          :devel_deps          => false,
          :highlight_missing   => false,
          :check_fedora        => false,
          :check_git           => false,
          :check_koji          => false,
          :koji_tag            => 'dist-rawhide',
          :check_rhn           => false,
          :check_yum           => false}

optparse = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this help screen') do
    puts opts
    exit
  end

  opts.on('--gemfile file', 'Location of the gemfile to parse') do |g|
    $conf[:gemfile] = g
  end

  opts.on('--gemspec file', 'Location of the gemspec to parse') do |g|
    $conf[:gemspec] = g
  end

  opts.on('--bundler', 'Use bundler to process the gemfile (note this eval\'s the Gemfile') do
    $conf[:bundler] = true
  end

  opts.on('--gem name', 'Name of the rubygem to check') do |g|
    $conf[:gemname] = g
  end

  opts.on('--gem-version version', 'Version of the rubygem to check (optional)') do |v|
    $conf[:gemversion] = v
  end

  opts.on('--[no-]devel', 'Include development dependencies') do |d|
    $conf[:devel_deps] = d
  end

  opts.on('-m', '--[no-]missing', 'Highlight missing packages') do |m|
    $conf[:highlight_missing] = m
  end

  opts.on('-f', '--[no-]fedora', 'Check fedora for packages') do |f|
    $conf[:check_fedora] = f
  end

  opts.on('-g', '--git [url]', 'Check git for packages') do |g|
    $conf[:check_git] = g || "git://pkgs.fedoraproject.org/"
  end

  opts.on('-k', '--koji [url]', 'Check koji for packages') do |k|
    $conf[:check_koji] = k || 'koji.fedoraproject.org'
  end

  opts.on('-t', '--koji-tag tag', 'Koji tag to query') do |t|
    $conf[:koji_tag] = t
  end

  opts.on('-b', '--bodhi [url]', 'Check Bodhi for packages') do |r|
    $conf[:check_bodhi] = r || 'https://admin.fedoraproject.org/updates/'
  end

  opts.on('-r', '--rhn [url]', 'Check RHN for packages') do |r|
    $conf[:check_rhn] = r || 'TODO'
  end

  opts.on('-y', '--yum', 'Check yum for packages') do |y|
    $conf[:check_yum] = y
  end
end

optparse.parse!

$conf[:gemfile] = './Gemfile' if $conf[:gemfile].nil? && File.exists?('./Gemfile')

unless ($conf[:gemfile] && File.exists?($conf[:gemfile])) ||
       ($conf[:gemspec] && File.exists?($conf[:gemspec])) ||
       !$conf[:gemname].nil?
  puts "Valid Gemfile, GemSpec, or Gem must be specified".bold.red
  exit 1
end

#gemfile_dir = File.split(File.expand_path($conf[:gemfile])).first
#Dir.chdir gemfile_dir

##########################################################

def check_local(name, version)
  if $conf[:highlight_missing]
    has =
      !$local_db.find { |s|
         s.satisfies_requirement?(Gem::Dependency.new(name, version))
       }.nil?

    if has
      print " is installed locally".green
    else
      print " is missing locally".red
    end
  end
end

def check_fedora(name)
  if $conf[:check_fedora]
    avail = Pkgwat.get_package("rubygem-#{name}") # TODO set timeout
    if avail
      print " is available in fedora".green
    else
      print " is not available in fedora".red
    end
  end
end

def check_koji(name)
  if $conf[:check_koji]
    $x ||= XMLRPC::Client.new($conf[:check_koji], '/kojihub')
    $last_event ||= $x.call('getLastEvent')['id']
    # FIXME pkg may need ruby193 or other prefix
    avail = $x.call('getLatestBuilds', $conf[:koji_tag], $last_event, "rubygem-#{name}").size > 0
    
    if avail
      print " is available in koji".green
    else
      print " is not available in koji".red
    end
  end
end

def check_git(name)
  if $conf[:check_git]
    avail = true
    Dir.mktmpdir { |dir|
      Dir.chdir(dir) { |path|
        begin
          g = Git.clone("#{$conf[:check_git]}rubygem-#{name}.git", name)
        rescue => e
          avail = false
        end
      }
    }

    if avail
      print " is available in git".green
    else
      print " is not available in git".red
    end
  end
end

def check_bodhi(name)
  if $conf[:check_bodhi]
    # we use the fedora pkgwat api to get the builds as thats a frontend for bodhi
    updates = Pkgwat.get_updates("rubygem-#{name}", 'all', 'all') # TODO set timeout
    updates.reject! { |u|
      u['stable_version'] == 'None' &&
      u['testing_version'] == "None"
    }

    if updates.empty?
      print " no updates found".red
    else
      print " #{updates.size} updates found".green
      print " (#{updates.collect { |u| u['release'] }.join(', ')})".green
    end
  end
end

def check_rhn(name)
  # TODO
end

def check_yum(name)
  if $conf[:check_yum]
    out=`/usr/bin/yum search rubygem-#{name} 2> /dev/null`
    if out =~ /.*No Matches found.*/
      print " no yum matches".red
    else
      matches = out.lines.to_a.reject { |l| l !~ /rubygem-#{name}.*/ }
      print " #{matches.size} yum matches found".green
    end
  end
end

def check_apt(name)
  # TODO
end

def check_bugzilla(name)
  # TODO
end

def check_all(name, version=nil)
  check_local(name, version)
  check_fedora(name)
  check_koji(name)
  check_git(name)
  check_bodhi(name)
  check_yum(name)
  puts ""
end

##########################################################

def check_gem(name, version=nil)
  $processed ||= []
  return if $processed.include?(name)
  $processed << name

  $indent ||= 0
  $indent += 1
  print "#{" " * $indent}#{name} #{version}".bold.yellow

  check_all(name, version)

  # TODO the rubygem specfetcher isn't terribly efficient,
  #      we may be able to optimize / write one of our own
  d = $conf[:gemversion] ? Gem::Dependency.new(name, version) :
                           Gem::Dependency.new(name)
  s = Gem::SpecFetcher.fetcher.fetch_with_errors(d, true, true, true)

  unless s[-2].nil? || s[-2].last.nil? || s[-2].last[0].nil?
    deps = s[-2].last[0].dependencies
    deps.each do |d|
      if d.type == :development && $conf[:devel_deps] == false
        puts "#{" " * $indent} skipping devel dependency #{d.name}"
      else
        check_gem(d.name, d.requirements_list.last.to_s)
      end
    end
  end

  $indent -= 1
end

def check_gemfile(gemfile)
  gemfile.dependencies.each { |d|
    name    = d.name
    req     = d.requirement

    print "#{name} #{req}".bold.yellow
    check_all(name, req)
  }
end

$local_db = Gem::Specification.all

if $conf[:gemname]
  check_gem($conf[:gemname], $conf[:gem_version])

elsif $conf[:bundler]
  require 'bundler'
  $gems = []

  # override bundler's gem registration
  module Bundler
    class Dsl
      alias :old_gem :gem
      def gem(name, *args)
        $gems << [name, args.first] # name,version
        old_gem(name, *args)
    end
    end
  end

  path,g = File.split($conf[:gemfile])
  Dir.chdir(path) {
    Bundler::Definition.build(g, nil, false)
  }

  $gems.each { |n,v|
    check_gem(n, v)
  }

else
  require 'gemnasium/parser'
  parser = $conf[:gemspec] ? Gemnasium::Parser.gemspec(File.read($conf[:gemspec])) :
                             Gemnasium::Parser.gemfile(File.read($conf[:gemfile]))
  check_gemfile(parser)
end
##########################################################
