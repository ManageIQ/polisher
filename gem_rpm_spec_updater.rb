#!/usr/bin/ruby
# gem rpm spec updater
#
# Simple tool to update the rpm spec of a packaged gem
# the latest version from rubygems.
#
# Use should specify the location of the rpm spec to
# manipulate and optionally a sepifier restricting the
# version to update to or the location of the gem/gemspec/gemfile
# source which parse and use.
#
# Usage: 
#   gem_spec_updater.rb <path-to-spec> <optional-source-or-version>
#
# Licensed under the MIT License
# Copyright (C) 2013 Red Hat, Inc.

require 'curb'
require 'json'
require 'bundler'
require 'colored'
require 'tempfile'
require 'pathname'
require 'rubygems/installer'
require 'active_support/core_ext'

AUTHOR = "#{ENV['USER']} <#{ENV['USER']}@localhost.localdomain>"

COMMENT_MATCHER             = /^\s*#.*/
GEM_NAME_MATCHER            = /^%global\s*gem_name\s(.*)$/
SPEC_NAME_MATCHER           = /^Name:\s*rubygem-(.*)$/
SPEC_VERSION_MATCHER        = /^Version:\s*(.*)$/
SPEC_RELEASE_MATCHER        = /^Release:\s*(.*)$/
SPEC_REQUIRES_MATCHER       = /^Requires:\s*(.*)$/
SPEC_BUILD_REQUIRES_MATCHER = /^BuildRequires:\s*(.*)$/
SPEC_GEM_REQ_MATCHER        = /^.*\s*rubygem\((.*)\)$/
SPEC_SUBPACKAGE_MATCHER     = /^%package\s(.*)$/
SPEC_CHANGELOG_MATCHER      = /^%changelog$/
SPEC_FILES_MATCHER          = /^%files$/
SPEC_SUBPKG_FILES_MATCHER   = /^%files\s*(.*)$/

FILE_MACRO_MATCHERS         =
  [/^%doc\s/,     /^%config\s/,  /^%attr\s/,
   /^%verify\s/,  /^%docdir.*/,  /^%dir\s/,
   /^%defattr.*/, /^%exclude\s/, /^%{gem_instdir}/]

FILE_MACRO_REPLACEMENTS =
  {"%{_bindir}"    => '/bin',
   "%{gem_libdir}" => '/lib'}

# Same bundler override as in gem_dependency_checker,
# possibly move some of this stuff out to an external
# gem/rpm management gem
module Bundler
  class << self
    attr_accessor :bundler_gems
  end

  class Dsl
    alias :old_gem :gem
    def gem(name, *args)
      Bundler.bundler_gems ||= []
      version = args.first.is_a?(Hash) ? nil : args.first
      Bundler.bundler_gems << [name, version]
      old_gem(name, *args)
    end
  end
end

$spec_file = ARGV.shift
$source    = ARGV.shift

# Parse RPM spec into metadata hash
def parse_spec
  in_subpackage = false
  in_changelog  = false
  in_files      = false
  subpkg_name   = nil
  $spec = {:contents => File.read($spec_file)}
  $spec[:contents].each_line { |l|
    if l =~ COMMENT_MATCHER
      ;

    # TODO support optional gem prefix
    elsif l =~ GEM_NAME_MATCHER
      $spec[:gem_name] = $1.strip
      $spec[:gem_name] = $1.strip

    elsif l =~ SPEC_NAME_MATCHER &&
          $1.strip != "%{gem_name}"
      $spec[:gem_name] = $1.strip

    elsif l =~ SPEC_VERSION_MATCHER
      $spec[:version] = $1.strip
      $version = $spec[:version]

    elsif l =~ SPEC_RELEASE_MATCHER
      $spec[:release] = $1.strip

    elsif l =~ SPEC_SUBPACKAGE_MATCHER
      subpkg_name = $1.strip
      in_subpackage = true

    elsif l =~ SPEC_REQUIRES_MATCHER &&
          !in_subpackage
      $spec[:requires] ||= []
      $spec[:requires] << $1.strip

    elsif l =~ SPEC_BUILD_REQUIRES_MATCHER &&
          !in_subpackage
      $spec[:build_requires] ||= []
      $spec[:build_requires] << $1.strip

    elsif l =~ SPEC_CHANGELOG_MATCHER
      in_changelog = true

    elsif l =~ SPEC_FILES_MATCHER
      subpkg_name = nil
      in_files = true

    elsif l =~ SPEC_SUBPKG_FILES_MATCHER
      subpkg_name = $1.strip
      in_files = true

    elsif in_changelog
      $spec[:changelog] ||= ""
      $spec[:changelog] << l

    elsif in_files
      tgt = subpkg_name.nil? ? $spec[:gem_name] : subpkg_name
      $spec[:files] ||= {}
      $spec[:files][tgt] ||= []

      sl = unrpmize_file(l.strip)
      $spec[:files][tgt] << sl unless sl.blank?
    end
  }

  $spec[:changelog_entries] =
    $spec[:changelog] ? $spec[:changelog].split("\n\n") : []
  $spec[:changelog_entries].collect! { |c| c.strip }.compact!
end

# Remove various possible rpm file list prefixes
def unrpmize_file(f)
  fmm = FILE_MACRO_MATCHERS
  fmr = FILE_MACRO_REPLACEMENTS
  f = fmm.inject(f) { |file, matcher| file.gsub(matcher, '') }
  f = fmr.keys.inject(f) { |file, r| file.gsub(Regexp.new(r), fmr[r]) }
  f
end

# Prep a file to be included in a rpm spec
def rpmize_file(f)
  fmr = FILE_MACRO_REPLACEMENTS.invert
  fmr.keys.inject(f) { |file, r| file.gsub(r, fmr[r]) }
end

# Return bool indicating if specified file is a gem
def is_file_gem?(path)
  File.extname(path) == ".gem"
end

# Return bool indicating if specified file is a gemspec
def is_file_gemspec?(path)
  File.extname(path) == ".gemspec"
end

# Return bool indicating if specified file is a Gemfile
def is_file_gemfile?(path)
  File.basename(path) == "Gemfile"
end

def parse_gem(gem_path)
  # TODO
end

def parse_gemspec(gemspec_path)
  gemspec = Gem::Specification.load(gemspec_path)
  $version  = gemspec.version
  $deps     = gemspec.runtime_dependencies.collect { |dep| dep.name }
  $dev_deps = gemspec.development_dependencies.collect { |dep| dep.name }
end

def parse_rubygems_metadata(metadata)
  specj     = JSON.parse(metadata)
  $version  = specj['version']
  $deps     = specj['dependencies']['runtime'].collect { |d| d['name'] }
  $dev_deps = specj['dependencies']['development'].collect { |d| d['name'] }
end

def parse_gemfile(gemfile_path)
  path,g = File.split(gemfile_path)
  Dir.chdir(path){
    Bundler::Definition.build(g, nil, false)
  }
  $deps     = Bundler.bundler_gems.collect { |n,v| n }
  $dev_deps = []
puts $deps
end

# Retrieve gem metadata from rubygems.org
def get_upstream_metadata
  if $source
    if File.file?($source)
      if is_file_gem?($source)
        parse_gem($source)

      elsif is_file_gemspec?($source)
        parse_gemspec($source)

      elsif is_file_gemfile?($source)
        parse_gemfile($source)

      end

    else
      $version = $source
      # TODO assume $source is a verison specifier, retrieve
      # gem from rubygems corresponding to version & parse
    end

  else
    gem_json_path = "https://rubygems.org/api/v1/gems/#{$spec[:gem_name]}.json"
    spec  = Curl::Easy.http_get(gem_json_path).body_str
    parse_rubygems_metadata(spec)

  end
end

# Retrieve gem contents from rubygems.org
def get_gem_contents
  gem_path = "https://rubygems.org/gems/#{$spec[:gem_name]}-#{$version}.gem"
  curl = Curl::Easy.new(gem_path)
  curl.follow_location = true
  curl.http_get
  gemf = curl.body_str

  tgem = Tempfile.new($spec[:gem_name])
  tgem.write gemf
  tgem.close

  $files = []
  pkg = Gem::Installer.new tgem.path, :unpack => true
  Dir.mktmpdir { |dir|
    pkg.unpack dir
    Pathname(dir).find do |path|
      pathstr = path.to_s.gsub(dir, '')
      $files << pathstr unless pathstr.blank?
    end
  }
end

# Retrieve contents from upstream source
def get_upstream_contents
  if $source && is_file_gemfile?($source)
    $files = []
  else
    get_gem_contents
  end
end

# Update spec depedendencies
def update_deps
  non_gem_requires    = []
  non_gem_brequires   = []
  extra_gem_requires  = []
  extra_gem_brequires = []

  $spec[:requires].each { |r|
    if r !~ SPEC_GEM_REQ_MATCHER
      non_gem_requires << r
    elsif !$deps.include?($1)
      extra_gem_requires << r
    end
  }

  $spec[:build_requires].each { |r|
    if r !~ SPEC_GEM_REQ_MATCHER
      non_gem_brequires << r
    elsif !$dev_deps.include?($1)
      extra_gem_brequires << r
    end
  }

  $spec[:requires] = non_gem_requires + extra_gem_requires +
                     $deps.collect { |r| "rubygem(#{r})" }
  $spec[:build_requires] = non_gem_brequires + extra_gem_brequires +
                           $dev_deps.collect { |r| "rubygem(#{r})" }
end

# Update spec files
def update_files
  to_add = $files
  $spec[:files].each { |pkg,spec_files|
    ($files & to_add).each { |gem_file|
      # skip files already included in spec or in dir in spec
      has_file = spec_files.any? { |sf|
                   gem_file.gsub(sf,'') != gem_file
                 }

      to_add.delete(gem_file)
      to_add << rpmize_file(gem_file) if !has_file
    }
  }

  $spec[:new_files] = to_add
end

# Update spec metadata
def update_spec
  # update to new version
  $spec[:version] = $version

  # better release updating ?
  release = "1%{?dist}"
  $spec[:release] = release

  # update requires/buildrequires
  update_deps

  # add any new files, remove any old ones
  update_files

  # add changelog entry
  changelog_entry = <<EOS
* #{Time.now.strftime("%a %b %d %Y")} #{AUTHOR} - #{$version}-#{release}
- Update to version #{$version}
EOS
  $spec[:changelog_entries].unshift changelog_entry.rstrip
  $spec
end

def generate_spec
  # replace version / release
  $spec[:contents].gsub!(SPEC_VERSION_MATCHER, "Version: #{$spec[:version]}")
  $spec[:contents].gsub!(SPEC_RELEASE_MATCHER, "Release: #{$spec[:release]}")

  # add changelog entry
  cp  = $spec[:contents].index SPEC_CHANGELOG_MATCHER
  cpn = $spec[:contents].index "\n", cp
  $spec[:contents] = $spec[:contents][0...cpn+1] +
                     $spec[:changelog_entries].join("\n\n")

  # update requires/build requires
  rp   = $spec[:contents].index SPEC_REQUIRES_MATCHER
  brp  = $spec[:contents].index SPEC_BUILD_REQUIRES_MATCHER
  tp   = rp < brp ? rp : brp

  pp   = $spec[:contents].index SPEC_SUBPACKAGE_MATCHER
  pp   = -1 if pp.nil?

  lrp  = $spec[:contents].rindex SPEC_REQUIRES_MATCHER, pp
  lbrp = $spec[:contents].rindex SPEC_BUILD_REQUIRES_MATCHER, pp
  ltp  = lrp > lbrp ? lrp : lbrp

  ltpn = $spec[:contents].index "\n", ltp

  $spec[:contents].slice!(tp...ltpn)
  $spec[:contents].insert tp,
    ($spec[:requires].collect { |r| "Requires: #{r}" } +
     $spec[:build_requires].collect { |r| "BuildRequires: #{r}" }).join("\n")

  # add new files
   fp = $spec[:contents].index SPEC_FILES_MATCHER
  lfp = $spec[:contents].index SPEC_SUBPKG_FILES_MATCHER, fp + 1
  lfp = $spec[:contents].index SPEC_CHANGELOG_MATCHER if lfp.nil?

  $spec[:contents].insert lfp - 1, $spec[:new_files].join("\n") + "\n"

  # return new contents
  $spec[:contents]
end

parse_spec
get_upstream_metadata
get_upstream_contents
update_spec
puts generate_spec.yellow.bold
