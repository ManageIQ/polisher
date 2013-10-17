#!/usr/bin/ruby
# Gem Dependency Checker
# Print out Gem/Gemspec/Gemfile dependencies, highlighting
# missing dependencies and those that are remotely
# available in various locations including koji,
# git, fedora, bodhi, rhn, etc.
#
# User is responsible for establishing authorization session
# before invoking this script
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
require 'curb'
require 'json'

XMLRPC::Config::ENABLE_NIL_PARSER = true
XMLRPC::Config::ENABLE_NIL_CREATE = true

##########################################################

$conf = { :gemfile             => './Gemfile',
          :bundler             => false,
          :gemspec             => nil,
          :gemname             => nil,
          :gemversion          => nil,
          :devel_deps          => false,
          :rpm_prefix          => 'rubygem-',
          :highlight_missing   => false,
          :check_fedora        => false,
          :check_git           => false,
          :check_koji          => false,
          :koji_tag            => 'dist-rawhide',
          :check_rhn           => false,
          :check_yum           => false,
          :check_bugzilla      => false,
          :check_errata        => false,
          :errata_advisory     => nil}

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

  opts.on('-r', '--rpm-prefix [prefix]', 'Prefix to add to gem package name when looking up in rpm resources') do |p|
    $conf[:rpm_prefix] = p
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
    $conf[:check_koji] = k || 'koji.fedoraproject.org/kojihub'
  end

  opts.on('-t', '--koji-tag tag', 'Koji tag to query') do |t|
    $conf[:koji_tag] = t
  end

  opts.on('-b', '--bodhi [url]', 'Check Bodhi for packages') do |r|
    $conf[:check_bodhi] = r || 'https://admin.fedoraproject.org/updates/'
  end

  opts.on('--rhn [url]', 'Check RHN for packages') do |r|
    $conf[:check_rhn] = r || 'TODO'
  end

  opts.on('-y', '--yum', 'Check yum for packages') do |y|
    $conf[:check_yum] = y
  end

  opts.on('-b', '--bugzilla', 'Check bugzilla for bugs filed against package') do |b|
    $conf[:check_bugzilla] = b
  end

  opts.on('-e', '--errata [url]', 'Check packages filed in errata') do |e|
    $conf[:check_errata] = e || nil
  end

  opts.on('-a', '--advisory [number]', 'Errata advisory to check') do |a|
    $conf[:errata_advisory] = a || nil
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

  nil
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

  nil
end

def check_koji(name, version)
  if $conf[:check_koji]
    $u ||= $conf[:check_koji].split('/')
    $x ||= XMLRPC::Client.new($u[0..-2].join('/'), '/' + $u.last)
    #$last_event ||= $x.call('getLastEvent')['id']
    nbuilds = $x.call('listTagged', $conf[:koji_tag], nil, false, nil, false, "#{$conf[:rpm_prefix]}#{name}")
    pbuilds =
      if version
        dep = Gem::Dependency.new(name, version)
        nbuilds.select { |b| dep.match?(name, b['version']) }
      else
        nbuilds
      end
    avail = pbuilds.size > 0
    
    if avail
      print " is available in koji".green
      return pbuilds.first['version']
    else
      print " is not available in koji".red
    end
  end

  nil
end

# utility method to extract required rpm spec metadata
def rpm_spec_metadata(path)
  metadata = {}
  contents = File.read(path)
  contents.each_line { |l|
    if l =~ /^Name:\s*rubygem-(.*)$/
      metadata[:name] = $1.strip
    elsif l =~ /^Version:\s*(.*)$/
      metadata[:version] = $1.strip
    end
  }
  metadata
end

def check_git(name, version)
  if $conf[:check_git]
    avail = true ; git_version = nil
    dep = version ? Gem::Dependency.new(name, version) : nil
    Dir.mktmpdir { |dir|
      Dir.chdir(dir) { |path|
        begin
          g = Git.clone("#{$conf[:check_git]}rubygem-#{name}.git", name)
          rpm_spec = rpm_spec_metadata("./#{name}/rubygem-#{name}.spec")
          git_version = rpm_spec[:version]

          if version
            avail = dep.match?(name, git_version)
          end
        rescue => e
          avail = false
        end
      }
    }

    if avail
      print " is available in git".green
      return git_version
    else
      print " is not available in git".red
    end
  end

  nil
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

  nil
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

  nil
end

def check_apt(name)
  # TODO
end

def check_bugzilla(name)
  if $conf[:check_bugzilla]
    # TODO
  end

  nil
end

def check_errata(name, version)
  if $conf[:check_errata] && $conf[:errata_advisory]
    unless $advisory_json
      c = Curl::Easy.new $conf[:check_errata] + $conf[:errata_advisory] + '/builds'
      c.ssl_verify_peer = false
      c.ssl_verify_host = false
      c.http_auth_types = :negotiate
      c.userpwd = ':'
      c.get
      $advisory_json = JSON.parse c.body_str
    end

    dep = Gem::Dependency.new(name, version)
    matched = false

    $advisory_json.each { |tag, builds|
      builds.each { |build|
        pkg,meta = *build.flatten
        if pkg =~ /^#{$conf[:rpm_prefix]}#{name}-([^-]*)-.*$/
          if dep.match?(name, $1)
            matched = true
            print "found in errata advisory".green
            break
          end
        end
      }
    }

    print "no matching errata advisory builds found".red unless matched
  end

  nil
end

def check_all(name, version=nil)
  lv = check_local(name, version)
  fv = check_fedora(name)
  kv = check_koji(name, version)
  gv = check_git(name, version)
  bhv = check_bodhi(name)
  yv = check_yum(name)
  bzv = check_bugzilla(name)
  erv = check_errata(name, version)
  puts ""

  version = nil ; counter = {}
  [lv, fv, kv, gv, bhv, yv, bzv, erv].each { |v|
    unless v.nil?
      counter[v] ||= 0
      counter[v]  += 1
      version = v if version.nil? || counter[v] > counter[version]
    end
  }
  version
end

##########################################################

def check_gem(name, version=nil)
  $processed ||= []
  return if $processed.include?(name)
  $processed << name

  $indent ||= 0
  $indent += 1
  print "#{" " * $indent}#{name} #{version}".bold.yellow

  checked_version = check_all(name, version)

  # TODO the rubygem specfetcher isn't terribly efficient,
  #      we may be able to optimize / write one of our own
  d = version ? Gem::Dependency.new(name, version) :
                Gem::Dependency.new(name)
  s = Gem::SpecFetcher.fetcher.fetch_with_errors(d, true, true, true)
  s = s.collect { |s1| s1.collect { |s2| s2.first if s2.is_a?(Array) } }.flatten
  s.compact!

  unless s.empty?
    matched = s.find { |s| s.version.to_s == checked_version }
    if matched.nil?
      matched = s.first
      # TODO puts " #{checked_version} not found, using first match from rubygems #{matched}"
    end

    deps = matched.dependencies
    deps.each do |d|
      if d.type == :development && $conf[:devel_deps] == false
        puts "#{" " * $indent} skipping devel dependency #{d.name}"
      else
        check_gem(d.name, d.requirements_list.last.to_s)
        # TODO if requirement not found, attempt to search for package and list all/lastest avail versions?
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
        version = args.first.is_a?(Hash) ? nil : args.first
        $gems << [name, version]
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
