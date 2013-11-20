# Polisher Project Rakefile
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require "rspec/core/rake_task"

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'specs/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace', '-fd', '-c']
end
