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

def check_missing
  missing_deps.each { |name, deps|
    latest   = latest_alt(name)
    print "#{name}(#{latest}) #{deps.collect { |dep| dep.requirement.to_s }}: ".blue.bold

    if !upstream_version?(name)
      puts "No matching upstream versions".red.bold

    else
      updatable = updatable_versions(name)

      if updatable.empty?
        puts "No matching upstream version > #{latest} (downstream)".red.bold

      else
        puts "Update to #{updatable.max}".green.bold

      end
    end
  }
end

def check_gems2update(source)
  msg = 'processing dependencies'
  waiting :msg => msg, :color => :red

  source.dependency_tree(:recursive => true,
                         :dev_deps  => dev_deps?) do |src, dep, resolved_dep|
    waiting_msg "#{msg} #{src.is_a?(Polisher::Gemfile) ? "Gemfile" : src.name}(#{dep.name})"
    check_missing_dep dep
  end

  end_waiting
  check_missing
end

def check_gems(conf)
  check_gems2update(conf_source) if conf_gem? || conf_gemfile?
end
