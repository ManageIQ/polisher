# Polisher Spec Helper
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

SPEC_DIR = File.expand_path File.dirname(__FILE__)

require 'polisher/rpmspec'

module Polisher
  module Test
    GEM_SPEC = {
      :path     => "#{SPEC_DIR}/data/mysql-2.9.1.gemspec",
      :name     => 'mysql',
      :version  => '2.9.1',
      :deps     => [],
      :dev_deps => [::Gem::Dependency.new('rdoc', '~> 3.10', :development),
                    ::Gem::Dependency.new('rake-compiler', '~> 0.8.1', :development),
                    ::Gem::Dependency.new('hoe', '~> 3.5', :development)]
    }

    GEM_JSON = {
      :url      => "https://rubygems.org/api/v1/gems/rails.json",
      :json     => File.read("#{SPEC_DIR}/data/rails.json"),
      :name     => 'rails',
      :version  => '4.0.1',
      :deps     => [::Gem::Dependency.new("actionmailer", '= 4.0.1'),
                    ::Gem::Dependency.new("actionpack", '= 4.0.1'),
                    ::Gem::Dependency.new("activerecord", '= 4.0.1'),
                    ::Gem::Dependency.new("activesupport", '= 4.0.1'),
                    ::Gem::Dependency.new("bundler", "< 2.0", ">= 1.3.0"),
                    ::Gem::Dependency.new("railties", '= 4.0.1'),
                    ::Gem::Dependency.new("sprockets-rails", '~> 2.0.0')],
      :dev_deps => []
    }

    LOCAL_GEM = {
      :json_url =>  "https://rubygems.org/api/v1/gems/rspec.json",
      :json     => File.read("#{SPEC_DIR}/data/rspec.json"),
      :url      => "https://rubygems.org/gems/rspec-2.12.0.gem",
      :contents => File.read("#{SPEC_DIR}/data/rspec-2.12.0.gem"),
      :name     => 'rspec',
      :version  => '2.12.0',
      :deps     => [::Gem::Dependency.new('rspec-core', '~> 2.14.0'),
                    ::Gem::Dependency.new('rspec-expectations', '~> 2.14.0'),
                    ::Gem::Dependency.new('rspec-mocks', '~> 2.14.0')],
      :dev_deps => [],
      :files    => ['License.txt', 'README.md', 'lib', 'lib/rspec', 'lib/rspec/version.rb', 'lib/rspec.rb']
    }

    GEMFILE = {
      :path     => "#{SPEC_DIR}/data/Gemfile",
      :contents => File.read("#{SPEC_DIR}/data/Gemfile"),
      :deps     => ['rubygems', 'cinch']
    }

    RPM_SPEC = {
      :path     => "#{SPEC_DIR}/data/rubygem-activesupport.spec",
      :contents => File.read("#{SPEC_DIR}/data/rubygem-activesupport.spec"),
      :name     => "activesupport",
      :version  => "4.0.0",
      :release  => "1%{?dist}",
      :requires => [Polisher::RPMSpec::Requirement.parse("ruby(rubygems)"),
                    Polisher::RPMSpec::Requirement.parse("ruby(release)"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(bigdecimal)"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(dalli)"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(i18n) >= 0.6"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(i18n) < 1.0"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(minitest) >= 4.2"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(minitest) < 5"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(multi_json) >= 1.0"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(multi_json) < 2"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(rack)"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(thread_safe)"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(tzinfo) >= 0.3.37"),
                    Polisher::RPMSpec::Requirement.parse("rubygem(tzinfo) < 0.4.0")],
      :build_requires => [Polisher::RPMSpec::Requirement.parse("rubygems-devel"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(bigdecimal)"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(builder)"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(dalli)"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(i18n) >= 0.6"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(i18n) < 1.0"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(minitest)"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(mocha)"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(multi_json) >= 1.0"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(multi_json) < 2"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(rack)"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(thread_safe)"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(tzinfo) >= 0.3.37"),
                          Polisher::RPMSpec::Requirement.parse("rubygem(tzinfo) < 0.4.0")],
      :changelog => "",
      :files     => {"activesupport"=>["%{gem_instdir}", "CHANGELOG.md", "lib", "MIT-LICENSE", "README.rdoc", "%{gem_docdir}", "%{gem_cache}", "%{gem_spec}", "test"]}
    }
  end # module Test
end # module Polisher
