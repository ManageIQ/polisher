#!/usr/bin/ruby
# Polisher CLI Updater Utils
#
# Licensed under the MIT license
# Copyright (C) 2016 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def update_conf
      { :gems     => [],
        :versions => [],
        :deps     => [] }
    end

    def update_options(option_parser)
      option_parser.on('-n', '--name GEM', 'gem name(s)' ) do |n|
        mark_for_update n
      end

      option_parser.on('-v', '--version version', 'version of last gem specified') do |v|
        set_update_version v
      end
    end

    def mark_for_update(name)
      conf[:gems]     << name
      conf[:versions] << nil
      conf[:deps]     << nil
    end

    def set_update_version(version)
      conf[:versions][-1] = version
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

    def update_gems
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

        update_gem
        update_gem_deps if specified_gem_deps? && !skip_gem_deps?
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

    def update_gem
      return if distgit_pkg.nil?

      update_git
      scratch_build
      verify_check_section
      git_commit

      print_results
    end

    def update_gem_deps
      (upstream_gem.deps + upstream_gem.dev_deps).each do |dep|
        # XXX ignoring duplicate gems here, even if they specify alt deps
        unless conf[:gems].include?(dep.name)
          mark_for_update dep.name
          conf[:deps][-1] = dep
        end
      end
    end
  end # module CLI
end # module Polisher
