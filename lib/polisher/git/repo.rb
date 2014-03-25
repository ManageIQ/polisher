# Polisher Git Repo Representation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'rugged'
require 'awesome_spawn'

require 'polisher/core'
require 'polisher/user'
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
        @path ||= GitCache.path_for(@url)
      end

      def author
        @author ||= {:email=> User.email, :name => User.name}
      end

      private

      def rugged
        @rugged ||= Rugged::Repository.new path
      end

      public
  
      # Clobber the git repo
      def clobber!
        FileUtils.rm_rf path
      end
  
      def clone
        Rugged::Repository.clone_at url, path
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
        rugged.reset 'HEAD~', :hard
        self
      end
  
      def pull
        in_repo { AwesomeSpawn.run "#{git_cmd} pull" }
        self
      end
  
      def checkout(tgt)
        # TODO repo.checkout implement in upstream rugged
        # (not in latest release yet), when available use that here
        in_repo { AwesomeSpawn.run "#{git_cmd} checkout #{tgt}" }
        self
      end
  
      def commit(msg)
        commit_author = author.merge{:time => Time.now}

        # FIXME need to add outstanding file changes to index:
        tree = repo.index.write_tree(repo)
        Rugged::Commit.create(rugged,
                              :author     => commit_author,
                              :committer  => commit_author,
                              :message    => msg,
                              :parents    => [repo.head.target],
                              :tree       => tree,
                              :update_ref => "HEAD")
        self
      end
    end # class Repo
  end # module Git
end # module Polisher
