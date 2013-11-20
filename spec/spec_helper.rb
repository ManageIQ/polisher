# Polisher Spec Helper
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

SPEC_DIR = File.expand_path File.dirname(__FILE__)

module Polisher
  module Test
    GEM_SPEC = {
      :path     => "#{SPEC_DIR}/data/mysql-2.9.1.gemspec",
      :name     => 'mysql',
      :version  => '2.9.1',
      :deps     => [],
      :dev_deps => ['rdoc', 'rake-compiler', 'hoe']
    }

    GEM_JSON = {
      :url      => "https://rubygems.org/api/v1/gems/rails.json",
      :json     => File.read("#{SPEC_DIR}/data/rails.json"),
      :name     => 'rails',
      :version  => '4.0.1',
      :deps     => ["actionmailer", "actionpack", "activerecord", "activesupport", "bundler", "railties", "sprockets-rails"],
      :dev_deps => []
    }

    LOCAL_GEM = {
      :json_url =>  "https://rubygems.org/api/v1/gems/rspec.json",
      :json     => File.read("#{SPEC_DIR}/data/rspec.json"),
      :url      => "https://rubygems.org/gems/rspec-2.12.0.gem",
      :contents => File.read("#{SPEC_DIR}/data/rspec-2.12.0.gem"),
      :name     => 'rspec',
      :version  => '2.12.0',
      :deps     => ['rspec-core', 'rspec-expectations', 'rspec-mocks'],
      :dev_deps => [],
      :files    => ['/License.txt', '/README.md', '/lib', '/lib/rspec', '/lib/rspec/version.rb', '/lib/rspec.rb']
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
      :requires => ["ruby(rubygems)", "ruby(release)", "rubygem(bigdecimal)", "rubygem(dalli)", "rubygem(i18n) >= 0.6", "rubygem(i18n) < 1.0", "rubygem(minitest) >= 4.2", "rubygem(minitest) < 5", "rubygem(multi_json) >= 1.0", "rubygem(multi_json) < 2", "rubygem(rack)", "rubygem(thread_safe)", "rubygem(tzinfo) >= 0.3.37", "rubygem(tzinfo) < 0.4.0"],
      :build_requires => ["rubygems-devel", "rubygem(bigdecimal)", "rubygem(builder)", "rubygem(dalli)", "rubygem(i18n) >= 0.6", "rubygem(i18n) < 1.0", "rubygem(minitest)", "rubygem(mocha)", "rubygem(multi_json) >= 1.0", "rubygem(multi_json) < 2", "rubygem(rack)", "rubygem(thread_safe)", "rubygem(tzinfo) >= 0.3.37", "rubygem(tzinfo) < 0.4.0"],
      :changelog => "",
      :files     => {"activesupport"=>["/CHANGELOG.md", "/lib", "/MIT-LICENSE", "/README.rdoc", "%{gem_docdir}", "%{gem_cache}", "%{gem_spec}", "/test"]}
    }
  end # module Test
end # module Polisher
