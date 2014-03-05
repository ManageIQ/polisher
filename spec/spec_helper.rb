# Polisher Spec Helper
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

SPEC_DIR = File.expand_path File.dirname(__FILE__)

begin
  require 'coveralls'
  Coveralls.wear!
rescue LoadError
end

require 'polisher/rpm/spec'
require 'polisher/gem_cache'

RSpec.configure do |config|
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.after do
    Polisher::GemCache.clear!
  end
end

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
      :version  => '2.14.1',
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
      :requires => [Polisher::RPM::Requirement.parse("ruby(rubygems)"),
                    Polisher::RPM::Requirement.parse("ruby(release)"),
                    Polisher::RPM::Requirement.parse("rubygem(bigdecimal)"),
                    Polisher::RPM::Requirement.parse("rubygem(dalli)"),
                    Polisher::RPM::Requirement.parse("rubygem(i18n) >= 0.6"),
                    Polisher::RPM::Requirement.parse("rubygem(i18n) < 1.0"),
                    Polisher::RPM::Requirement.parse("rubygem(minitest) >= 4.2"),
                    Polisher::RPM::Requirement.parse("rubygem(minitest) < 5"),
                    Polisher::RPM::Requirement.parse("rubygem(multi_json) >= 1.0"),
                    Polisher::RPM::Requirement.parse("rubygem(multi_json) < 2"),
                    Polisher::RPM::Requirement.parse("rubygem(rack)"),
                    Polisher::RPM::Requirement.parse("rubygem(thread_safe)"),
                    Polisher::RPM::Requirement.parse("rubygem(tzinfo) >= 0.3.37"),
                    Polisher::RPM::Requirement.parse("rubygem(tzinfo) < 0.4.0")],
      :build_requires => [Polisher::RPM::Requirement.parse("rubygems-devel"),
                          Polisher::RPM::Requirement.parse("rubygem(bigdecimal)"),
                          Polisher::RPM::Requirement.parse("rubygem(builder)"),
                          Polisher::RPM::Requirement.parse("rubygem(dalli)"),
                          Polisher::RPM::Requirement.parse("rubygem(i18n) >= 0.6"),
                          Polisher::RPM::Requirement.parse("rubygem(i18n) < 1.0"),
                          Polisher::RPM::Requirement.parse("rubygem(minitest)"),
                          Polisher::RPM::Requirement.parse("rubygem(mocha)"),
                          Polisher::RPM::Requirement.parse("rubygem(multi_json) >= 1.0"),
                          Polisher::RPM::Requirement.parse("rubygem(multi_json) < 2"),
                          Polisher::RPM::Requirement.parse("rubygem(rack)"),
                          Polisher::RPM::Requirement.parse("rubygem(thread_safe)"),
                          Polisher::RPM::Requirement.parse("rubygem(tzinfo) >= 0.3.37"),
                          Polisher::RPM::Requirement.parse("rubygem(tzinfo) < 0.4.0")],
      :changelog => "",
      :files     => {"activesupport"=>["%{gem_instdir}", "CHANGELOG.md", "lib", "MIT-LICENSE", "README.rdoc", "%{gem_docdir}", "%{gem_cache}", "%{gem_spec}", "test"]}
    }
  end # module Test
end # module Polisher
