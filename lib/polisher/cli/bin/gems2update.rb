# Polisher gem2update cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'optparse'

def gems2update_conf
  conf.merge!(default_conf)
      .merge!(targets_conf)
      .merge!(profiles_conf)
      .merge!(sources_conf)
end

def gems2update_parser
  OptionParser.new do |opts|
    default_options  opts
    targets_options  opts
    profiles_options opts
    sources_options  opts
  end
end

def check_missing(deps, alts)
  deps.each { |name, gdeps|
    versions = Polisher::Gem.remote_versions_for(name)
    matching = versions.select { |v| gdeps.all? { |dep| dep.match?(name, v)} }
    latest    = alts[name].max

    print "#{name}(#{latest}) #{gdeps.collect { |dep| dep.requirement.to_s }}: ".blue.bold

    if matching.empty?
      puts "No matching upstream versions".red.bold

    else
      updatable = latest.nil? ? matching : matching.select { |m| m > latest }

      if updatable.empty?
        puts "No matching upstream version > #{latest} (downstream)".red.bold

      else
        puts "Update to #{updatable.max}".green.bold

      end
    end
  }
end

def check_gems2update(source)
  deps = {}
  alts = {}

  msg = 'processing dependencies'
  waiting :msg => msg,
          :color => :red

  source.dependency_tree(:recursive => true,
                         :dev_deps  => conf[:devel_deps]) do |source, dep, resolved_dep|
    waiting_msg "#{msg} #{source.name}(#{dep.name})"

    # XXX : need to nullify dep.type for this lookup
    dep.instance_variable_set(:@type, :runtime)
    name = dep.name
    other_version_missing = deps.key?(name)
    has_dep = other_version_missing && deps[name].any? { |gdep| gdep == dep }

    unless has_dep
      versions = Polisher::VersionChecker.matching_versions(dep)
      missing_downstream = versions.empty?
    end

    if missing_downstream || other_version_missing
      deps[name] ||= []
      deps[name] << dep unless has_dep

      alts[name] = Polisher::VersionChecker.versions_for(name).values.flatten unless alts.key?(name)
    end
  end
  end_waiting
  check_missing(deps, alts)
end

def check_gems(conf)
  check_gems2update(conf_source) if conf_gem? || conf_gemfile?
end
