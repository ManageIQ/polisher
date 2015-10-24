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
    def orig_dir
      @orig_dir ||= Dir.pwd
    end

    def git_gem_updater_conf
      conf.merge!({ :dir      => orig_dir,
                    :user     =>      nil,
                    :gems     =>       [],
                    :versions =>       [] }).merge!(default_conf)
    end

    def git_gem_updater_options(option_parser)
      option_parser.on('-n', '--name GEM', 'gem name(s)' ) do |n|
        conf[:gems]     << n
        conf[:versions] << nil
      end

      option_parser.on('-v', '--version version', 'version of last gem specified') do |v|
        conf[:versions][-1] = v
      end

      option_parser.on('-u', '--user USER', 'fedora user name' ) do |u|
        conf[:user] = u
      end

      option_parser.on('-d', '--dir path', 'Directory to cd to before checking out / manipulating packages' ) do |p|
        conf[:dir] = p
      end
    end

    def git_gem_updater_option_parser
      OptionParser.new do |opts|
        default_options         opts
        git_gem_updater_options opts
      end
    end

    def validate_user!
      unless conf[:user].nil?
        begin
          conf[:gems] += Polisher::Fedora.gems_owned_by(conf[:user])
        rescue
          puts "Could not retrieve gems owned by #{conf[:user]}".red
          exit 1
        end
      end
    end

    def validate_gems!
      if conf[:gems].empty?
        puts "must specify a gem name or user name!".red
        exit 1
      end
    end

    def validate_args!
      validate_user!
      validate_gems!
    end

    def chdir
      Dir.mkdir conf[:dir] unless File.directory?(conf[:dir])
      Dir.chdir conf[:dir]
    end

     def current_gem(gem_name=nil, gem_version=nil)
      unless gem_name.nil?
        @distgit_pkg  = nil
        @upstream_gem = nil
        @gem_name     = gem_name
        @gem_version  = gem_version
      end

      @gem_name
    end

    def distgit_pkg
      @distgit_pkg ||= begin
        Polisher::Git::Pkg.new(:name => @gem_name).fetch
      rescue => e
        puts "Problem Cloning Package, Skipping: #{e}"
        nil
      end
    end

    def upstream_gem
      @upstream_gem ||= Polisher::Gem.retrieve @gem_name, @gem_version
    end

    def process_gems
      conf[:gems].each_index do |g|
        name    = conf[:gems][g]
        version = conf[:versions][g]
        current_gem name, version
        process_gem
      end
    end

    def update_args
      skip_gem_deps_args
    end

    def update_git
      distgit_pkg.update_to(upstream_gem, update_args)
      # TODO append gem dependencies to conf[:gems] list
    end

    def scratch_build
      begin
        distgit_pkg.build
      rescue => e
        puts "Warning: scratch build failed: #{e}".bold.red
      end
    end

    def verify_check_section
      unless distgit_pkg.spec.has_check?
        puts "Warning: no %check section in spec, "\
             "manually verify functionality!".bold.red
      end
    end

    def git_commit
      distgit_pkg.commit
    end

    def print_results
      puts "#{@gem_name} commit complete".green
      puts "Package located in #{distgit_pkg.path.bold}"
      puts "Push commit with: git push".blue
      puts "Build and tag official rpms with: #{Polisher::Git::Pkg.pkg_cmd} build".blue
    end

    def process_gem
      return if distgit_pkg.nil?

      update_git
      scratch_build
      verify_check_section
      git_commit

      print_results
    end
  end # module CLI
end # module Polisher
