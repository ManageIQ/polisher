# Polisher Git Repo Representation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/core'
require 'polisher/git_cache'
require 'polisher/component'

module Polisher
  module Git
    Component.verify("Git::Repo", 'awesome_spawn') do
      # Git Repository
      class Repo
        include ConfHelpers

        # TODO: use ruby git api
        conf_attr :git_cmd, '/usr/bin/git'

        attr_accessor :url
        attr_accessor :path

        def initialize(args = {})
          @url   = args[:url]
          @path  = args[:path]
        end

        def path
          @path || GitCache.path_for(@url)
        end

        # Clobber the git repo
        def clobber!
          FileUtils.rm_rf path
        end

        def clone
          require_cmd! git_cmd
          AwesomeSpawn.run! "#{git_cmd} clone #{url} #{path}"
        end

        def cloned?
          File.directory?(path)
        end

        def in_repo
          Dir.chdir path do
            yield
          end
        end

        def file_paths
          in_repo { Dir['**/*'] }
        end

        def include?(file)
          file_paths.include?(file)
        end

        # Note be careful when invoking:
        def reset!
          require_cmd! git_cmd
          in_repo { AwesomeSpawn.run! "#{git_cmd} reset HEAD~ --hard" }
          self
        end

        def pull
          require_cmd! git_cmd
          in_repo { AwesomeSpawn.run! "#{git_cmd} pull" }
          self
        end

        def checkout(tgt)
          require_cmd! git_cmd
          in_repo { AwesomeSpawn.run! "#{git_cmd} checkout #{tgt}" }
          self
        end

        def commit(msg)
          require_cmd! git_cmd
          in_repo { AwesomeSpawn.run! "#{git_cmd} commit -m '#{msg}'" }
          self
        end
      end # class Repo
    end # Component.verify("Git::Repo")
  end # module Git
end # module Polisher
