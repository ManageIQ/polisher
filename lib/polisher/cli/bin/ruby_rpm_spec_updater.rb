# Polisher ruby_rpm_spec_updater cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def parse_args
      conf[:spec_file] = ARGV.shift
      conf[:source]    = ARGV.shift
    end

    def verify_args!
      if conf[:spec_file].nil? || conf[:spec_file].blank?
        puts "Must specify specfile"
        exit 1
      end
    end

    def ruby_rpm_spec_updater_options(option_parser)
      option_parser.on('-i', 'In-place update of the spec file') do
        conf[:in_place] = true
      end
    end

    def ruby_rpm_spec_updater_option_parser
      OptionParser.new do |opts|
        default_options               opts
        gem_deps_options              opts
        ruby_rpm_spec_updater_options opts
      end
    end

    def rpmspec
      @rpmspec ||= Polisher::RPM::Spec.parse File.read(conf[:spec_file])
    end

    def source
      @source  ||= conf[:source].nil? ?
                     Polisher::Gem.retrieve(rpmspec.gem_name) :
                     Polisher::Upstream.parse(conf[:source])
    end

    def in_place?
      conf[:in_place]
    end

    def update_args
      skip_gem_deps_args
    end

    def update_in_place
      File.write(conf[:spec_file], rpmspec.to_string)
    end

    def update_to_stdout
      puts rpmspec.to_string
    end

    def run_update!
      rpmspec.update_to(source, update_args)
      in_place? ? update_in_place : update_to_stdout
    end
  end # module CLI
end # module Polisher
