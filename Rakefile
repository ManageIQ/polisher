# Polisher Project Rakefile
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task :test => :spec
  task :default => :spec
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
