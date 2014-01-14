# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'polisher/version'

PKG_FILES =
  Dir.glob('{lib,spec}/**/*.rb') +
  Dir.glob('spec/data/*') +
  ['LICENSE', 'Rakefile', 'README.md']

Gem::Specification.new do |s|
  # Dynamically create the authors information {name => e-mail}
  authors_hash = Hash[`git log --no-merges --reverse --format='%an,%ae'`.split("\n").uniq.collect {|i| i.split(",")}]

  s.author        = authors_hash.keys
  s.email         = authors_hash.values
  s.date          = %q{2014-01-14}
  s.summary       = %q{Ruby Project Post-Publishing Processor}
  s.description   = %q{General API and utility scripts to manipulate and query ruby gems and projects after being published}
  s.homepage      = %q{https://github.com/ManageIQ/polisher}
  s.licenses      = ["MIT"]

  s.name          = 'polisher'
  s.version       = Polisher::VERSION
  s.files         = PKG_FILES
  s.executables   = ['binary_gem_resolver.rb', 'gem_dependency_checker.rb',
                     'git_gem_updater.rb', 'ruby_rpm_spec_updater.rb']
  s.require_paths = ['lib']

  # TODO tighten up deps, some may be optional
  s.add_dependency('json')
  s.add_dependency('curb')
  s.add_dependency('active_support')
  s.add_dependency('i18n')
  s.add_dependency('bundler')
  s.add_dependency('pkgwat')
  s.add_dependency('colored')
  s.add_dependency('awesome_spawn')
  s.add_dependency('gem2rpm')
  s.add_development_dependency('rspec', '>= 2.0.0')
end
