# Polisher git_gem_updater cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'colored'

require 'polisher/gem'
require 'polisher/git/pkg'

module Polisher
  module CLI
    def git_gem_updater_conf
      conf.merge!(update_conf)
          .merge!(fedora_conf)
          .merge!(path_conf)
          .merge!(default_conf)
    end

    def git_gem_updater_option_parser
      OptionParser.new do |opts|
        default_options         opts
        gem_deps_options        opts
        path_options            opts
        fedora_options          opts
        update_options          opts
      end
    end

    def validate_gems!
      conf[:gems] += user_gems

      if conf[:gems].empty?
        puts "must specify a gem or user name!".red
        exit 1
      end
    end
  end # module CLI
end # module Polisher
