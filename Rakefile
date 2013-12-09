# Polisher Project Rakefile
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

begin
  require "rspec/core/rake_task"
  desc "Run all specs"
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'specs/**/*_spec.rb'
    spec.rspec_opts = ['--backtrace', '-fd', '-c']
  end
rescue LoadError
end

desc "build the polisher gem"
task :build do
  system "gem build polisher.gemspec"
end

begin
  require "yard"
  YARD::Rake::YardocTask.new do |t|
    #t.files   = ['lib/**/*.rb', OTHER_PATHS]   # optional
    #t.options = ['--any', '--extra', '--opts'] # optional
  end
rescue LoadError
end
