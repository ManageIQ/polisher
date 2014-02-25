# Polisher Git Repo Representation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'awesome_spawn'
require 'polisher/core'
require 'polisher/git_cache'

module Polisher
  module Git
    # Git Repository
    class Repo
      extend ConfHelpers
  
      # TODO use ruby git api
      conf_attr :git_cmd, '/usr/bin/git'
  
      attr_accessor :url
  
      def initialize(args={})
        @url  = args[:url]
      end
  
      def path
        GitCache.path_for(@url)
      end
  
      # Clobber the git repo
      def clobber!
        FileUtils.rm_rf path
      end
  
      def clone
        AwesomeSpawn.run "#{git_cmd} clone #{url} #{path}"
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
  
      # Note be careful when invoking:
      def reset!
        in_repo { AwesomeSpawn.run "#{git_cmd} reset HEAD~ --hard" }
        self
      end
  
      def pull
        in_repo { AwesomeSpawn.run "#{git_cmd} pull" }
        self
      end
  
      def checkout(tgt)
        in_repo { AwesomeSpawn.run "#{git_cmd} checkout #{tgt}" }
        self
      end
  
      def commit(msg)
        in_repo { AwesomeSpawn.run "#{git_cmd} commit -m '#{msg}'" }
        self
      end
    end # class Repo
  end # module Git
end # module Polisher
