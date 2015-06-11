# Polisher gem_mapper cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'optparse'

def gem_mapper_conf
  conf.merge!(default_conf)
      .merge!(specifier_conf)
      .merge!(sources_conf)
end

def gem_mapper_parser
  OptionParser.new do |opts|
    default_options(opts)
    sources_options(opts)
     specifier_opts(opts)
  end
end

def print_dep(gem, dep, resolved_dep)
  print pretty_dep(gem, dep, resolved_dep)
end

def print_deps(source)
  source.dependency_tree(:recursive => true,
                         :dev_deps  => conf[:devel_deps],
                         :matching  => conf[:matching]) do |gem, dep, resolved_dep|
    print_dep(gem, dep, resolved_dep)
  end
end

def print_tree(conf)
  print_deps(conf_source) if conf_gem? || conf_gemfile?
end
