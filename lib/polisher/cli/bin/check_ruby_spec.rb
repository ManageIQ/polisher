# Polisher check_ruby_spec  cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'colored'
require 'polisher/rpm'
require 'polisher/gem'

module Polisher
  module CLI
    def parse_args
      conf[:spec_file] = ARGV.shift
      conf[:source]    = ARGV.shift
    end

    def validate_args!
      if conf[:spec_file].nil?
        puts "Must specify spec file".bold.red
        exit 1
      end
    end

    def conf_spec
      @conf_spec ||= Polisher::RPM::Spec.parse File.read(conf[:spec_file])
    end

    def conf_source
      conf[:source].nil? ? Polisher::Gem.retrieve(conf_spec.gem_name) :
                           Polisher::Upstream.parse(conf[:source])
    end

    def run_check
      result  = conf_spec.compare(conf_source)
      no_diff = result[:diff].keys.empty?
      print_diff(result[:diff]) unless no_diff
    end

    def print_diff(diff)
      puts "differences between rpmspec and upstream source detected".red.bold
      diff.each do |dep, versions|
        print_dep_diff dep, versions
      end
    end

    def print_dep_diff(dep, versions)
      puts "#{dep} / " \
           "spec (#{versions[:spec]}) / " \
           "upstream #{versions[:upstream]}".bold.red
    end
  end # module CLI
end # module Polisher
