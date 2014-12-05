# Polisher Gemfile Deps Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/repo'
require 'polisher/gem'

module Polisher
  module GemfileDeps
    # Simply alias for all dependencies in Gemfile
    def vendored
      deps + dev_deps
    end

    # Retrieve gems which differ from
    # rubygems.org/other upstream sources
    def patched
      vendored.collect do |dep|
        # TODO: right now just handling git based alternate sources,
        # should be able to handle other types bundler supports
        # (path and alternate rubygems src)
        next unless dep.source.is_a?(Bundler::Source::Git)
        src = dep.source

        # retrieve gem
        gem = if src.version
                Polisher::Gem.new(:name => dep.name, :version => src.version)
              else
                Polisher::Gem.retrieve(dep.name)
              end

        # retrieve dep
        git = Polisher::Git::Repo.new :url => src.uri
        git.clone unless git.cloned?
        git.checkout src.ref if src.ref

        # diff gem against git
        gem.diff(git.path)
      end.compact!
    end
  end # module GemfileDeps
end # module Polisher
