# Polisher missing_deps cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'optparse'

def missing_deps_conf
  conf.merge!(default_conf)
      .merge!(targets_conf)
      .merge!(sources_conf)
end

def missing_deps_parser
  OptionParser.new do |opts|
    default_options opts
    targets_options opts
    sources_options opts
  end
end

def check_missing_deps(source)
  source.dependency_tree(:recursive => true,
                         :dev_deps  => conf[:devel_deps]) do |source, dep, resolved_dep|
    versions   = Polisher::VersionChecker.matching_versions(dep)
    alt        = Polisher::VersionChecker.versions_for(dep.name)
    source_str = source.is_a?(Polisher::Gemfile) ? "Gemfile" : "#{source.name} #{source.version}"
    puts "#{source_str} missing dep #{dep.name} #{dep.requirement} - alt versions: #{alt}" if versions.empty?
  end
end

def check_deps(conf)
  check_missing_deps(conf_source) if conf_gem? || conf_gemfile?
end
