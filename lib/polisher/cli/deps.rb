#!/usr/bin/ruby
# Polisher CLI Deps Specifier Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def specified_gem_deps?
      conf[:specified_gem_deps]
    end

    def skip_gem_deps?
      conf[:skip_gem_deps]
    end

    def skip_gem_deps_args
      {:skip_gem_deps      =>      skip_gem_deps?,
       :specified_gem_deps => specified_gem_deps?  }
    end

    def gem_deps_options(option_parser)
      option_parser.on('--gem-deps', 'Include gem dependencies') do
        conf[:specified_gem_deps] = true
        conf[:skip_gem_deps]      = false
      end

      option_parser.on('--skip-gem-deps', 'Skip gem dependencies') do
        conf[:specified_gem_deps] = true
        conf[:skip_gem_deps]      = true
      end
    end
  end # module CLI
end # module Polisher
