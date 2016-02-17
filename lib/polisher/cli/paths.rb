#!/usr/bin/ruby
# Polisher CLI Path Utils
#
# Licensed under the MIT license
# Copyright (C) 2016 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def orig_dir
      @orig_dir ||= Dir.pwd
    end

    def path_conf
      { :dir => orig_dir }
    end

    def path_options(option_parser)
      option_parser.on('-d', '--dir path', 'Directory to cd to before checking out / manipulating packages' ) do |p|
        conf[:dir] = p
      end
    end

    def chdir
      Dir.mkdir conf[:dir] unless File.directory?(conf[:dir])
      Dir.chdir conf[:dir]
    end
  end # module CLI
end # module Polisher
