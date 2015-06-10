#!/usr/bin/ruby
# Polisher CLI Gem Sources Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def sources_conf
      { :gemfile    => './Gemfile',
        :gemspec    => nil,
        :gemname    => nil,
        :gemversion => nil,
        :groups     => [],
        :devel_deps => false }
    end

    def sources_options(option_parser)
      option_parser.on('--gemfile file', 'Location of the gemfile to parse') do |g|
        conf[:gemfile] = g
      end

      option_parser.on('--group gemfile_groups', 'Gemfile groups (may be specified multiple times)') do |g|
        conf[:groups] << g
      end

      option_parser.on('--gemspec file', 'Location of the gemspec to parse') do |g|
        conf[:gemspec] = g
      end

      option_parser.on('--gem name', 'Name of the rubygem to check') do |g|
        conf[:gemname] = g
      end

      option_parser.on('-v', '--version [version]', 'Version of gem to check') do |v|
        conf[:gemversion] = v
      end

      option_parser.on('--[no-]devel', 'Include development dependencies') do |d|
        conf[:devel_deps] = d
      end
    end

    def validate_sources
      if conf[:gemfile].nil? &&
         conf[:gemspec].nil? &&
         conf[:gemname].nil?
      
         if File.exists?('./Gemfile')
           conf[:gemfile] = './Gemfile'
         else
           puts "Valid Gemfile, GemSpec, or Gem must be specified".bold.red
           exit 1
         end
      end
    end

    def conf_gem?
      conf[:gemname] || conf[:gemspec]
    end

    def conf_gemfile?
      !conf[:gemfile].nil?
    end

    def conf_source
      if conf[:gemname]
        conf[:gemversion] ? Polisher::Gem.from_rubygems(conf[:gemname], conf[:gemversion]) :
                            Polisher::Gem.retrieve(conf[:gemname])
      
      elsif conf[:gemspec]
        Polisher::Gem.from_gemspec(conf[:gemspec])
      
      elsif conf[:gemfile]
        gemfile = nil

        begin
          gemfile = Polisher::Gemfile.parse(conf[:gemfile], :groups => conf[:groups])
        rescue => e
          puts "Runtime err #{e}".red
          exit 1
        end

        gemfile
      end
    end
  end # module CLI
end # module Polisher
