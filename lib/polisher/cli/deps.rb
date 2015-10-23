#!/usr/bin/ruby
# Polisher CLI Deps Specifier Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def skip_gem_deps?
      conf[:skip_gem_deps]
    end

    def skip_gem_deps_args
      {:skip_gem_deps => skip_gem_deps?}
    end

    def gem_deps_options(option_parser)
      option_parser.on('--skip-gem-deps', 'Skip gem dependencies') do
        conf[:skip_gem_deps] = true
      end
    end
  end # module CLI
end # module Polisher
