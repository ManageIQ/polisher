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
                    :versions =>       [],
                    :deps     =>       []}).merge!(default_conf)
    end

    def git_gem_updater_options(option_parser)
      option_parser.on('-n', '--name GEM', 'gem name(s)' ) do |n|
        queue_gem n
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
        gem_deps_options        opts
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

    def queue_gem(name)
      conf[:gems]     << name
      conf[:versions] << nil
      conf[:deps]     << nil
    end

    def chdir
      Dir.mkdir conf[:dir] unless File.directory?(conf[:dir])
      Dir.chdir conf[:dir]
    end

     def current_gem(args={})
      @distgit_pkg  = nil
      @upstream_gem = nil
      @gem_name     = args[:name]
      @gem_version  = args[:version]
      @gem_dep      = args[:dep]
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
      @upstream_gem ||=
        if @gem_dep
          Polisher::Gem.latest_matching(@gem_dep)
        else
          Polisher::Gem.retrieve(@gem_name, @gem_version)
        end
    end

    def process_gems
      # TODO - Process deps & order gem list so dependencies are built before dependents.
      #      - Use chained scratch builds to make them available.
      #      - Add cli opt to exit entire sequence / executable if one in queue fails
      #      - Process gems & run builds in parallel
      conf[:gems].each_index do |g|
        name    = conf[:gems][g]
        version = conf[:versions][g]
        dep     = conf[:deps][g]
        current_gem :name    =>    name,
                    :version => version,
                    :dep     =>     dep

        process_gem
        process_gem_deps if specified_gem_deps? && !skip_gem_deps?
      end
    end

    def update_args
      skip_gem_deps_args
    end

    def update_git
      distgit_pkg.update_to(upstream_gem, update_args)
      # TODO append gem dependencies to conf[:gems] list
    end

    # TODO print koji url (both on success & failure)
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

    def process_gem_deps
      (upstream_gem.deps + upstream_gem.dev_deps).each do |dep|
        # XXX ignoring duplicate gems here, even if they specify alt deps
        unless conf[:gems].include?(dep.name)
          queue_gem dep.name
          conf[:deps][-1] = dep
        end
      end
    end
  end # module CLI
end # module Polisher
