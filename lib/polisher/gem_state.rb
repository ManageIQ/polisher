# Polisher Gem State Represenation
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/tag_mapper'

module Polisher
  module HasState
    def koji_tags
      Koji.tagged_version_for(name)
    end

    def koji_state(args = {})
      check_dep = args.key?(:check)

      return :missing   if koji_tags.empty?
      return :available unless check_dep

      koji_tags.each do |tag, version|
        return :available if !version.nil? && args[:check].match?(name, version)
      end

      return :missing
    end

    def distgit
      @distgit ||= Git::Pkg.new :name => name
    end

    def distgit_branches
      tags = []

      koji_tags.each do |tag, version|
        tag = TagMapper.map(tag)
        tags << tag unless tag.nil?
      end

      tags.empty? ? distgit.valid_branches : tags
    end

    def distgit_versions
      distgit_branches.collect do |branch|
        distgit.fetch branch
        distgit.spec.version if distgit.spec?
      end.compact
    end

    def distgit_state(args = {})
      check_dep = args.key?(:check)

      begin
        distgit.clone
      rescue
        return :missing_repo
      end

      return :missing_branch if distgit.valid_branches.empty?
      return :missing_spec   if distgit_versions.empty?
      return :available      unless check_dep

      distgit_versions.each do |version|
        return :available if args[:check].match?(name, version)
      end

      return :missing
    end

    # Return the 'state' of the gem as inferred by
    # the targets which there are versions for.
    #
    # If optional :check argument is specified, version
    # analysis will be restricted to targets satisfying
    # the specified gem dependency requirements
    def state(args = {})
      return :available if koji_state(args) == :available

      state = distgit_state(args)
      return :needs_repo   if state == :missing_repo
      return :needs_branch if state == :missing_branch
      return :needs_spec   if state == :missing_spec
      return :needs_build  if state == :available
      return :needs_update
    end
  end
end
