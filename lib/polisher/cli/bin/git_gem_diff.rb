# Polisher git_gem_diff cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'optparse'

module Polisher
  module CLI
    def git_gem_diff_conf
      conf.merge!({ :git => nil })
    end

    def git_gem_diff_options(option_parser)
      option_parser.on('-g', '--git [url]', 'url') do |url|
        conf[:git] = url
      end
    end

    def git_gem_diff_option_parser
      OptionParser.new do |opts|
        default_options      opts
        git_gem_diff_options opts
      end
    end

    def validate_args!
      if conf[:git].nil?
        puts "Must specify a git url".bold.red
        exit 1
      end
    end

    def git_repo
      @git_repo ||= begin
        git = Polisher::Git::Repo.new :url => conf[:git]
        git.clone unless git.cloned?
        git
      end
    end

    def gem_details
      @gem_details ||= begin
        name, version = nil
        git_repo.in_repo do
          gemspec_path = Dir.glob('*.gemspec').first
          gem          = Polisher::Gem.from_gemspec gemspec_path
          name    = gem.name
          version = gem.version
        end
        {:name => name, :version => version}
      end
    end

    def diff
      @diff ||= begin
        name    = gem_details[:name]
        version = gem_details[:version]
        Polisher::Gem.from_rubygems(name, version).diff(git_repo)
      end
    end
  end # module CLI
end # module Polisher
