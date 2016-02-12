# Polisher update_gems cli util
#
# Licensed under the MIT license
# Copyright (C) 2016 Red Hat, Inc.
###########################################################

require 'optparse'

def update_gems_conf
  conf.merge!(default_conf)
      .merge!(profiles_conf)
      .merge!(sources_conf)
end

def update_gems_parser
  OptionParser.new do |opts|
    default_options  opts
    profiles_options opts
    sources_options  opts
  end
end

def update_missing
  missing_deps.each { |name, deps|
    update_to = updatable_versions(name).max
    if update_to.nil?
      puts "No version to update #{name} to"
    else
      mark_for_update name
      set_update_version update_do
    end
  }

  update_gems
end

def run_gem_update(source)
  source.dependency_tree(:recursive => true,
                         :dev_deps  => dev_deps?) do |src, dep, resolved_dep|
    check_missing_dep dep
  end

  update_missing
end

def run_gems_update(conf)
  run_gem_update(conf_source) if conf_gem? || conf_gemfile?
end
