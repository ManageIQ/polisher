# Polisher Koji Build Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module KojiBuilder
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Run a build against the specified target using the specified rpm
      def build(args = {})
        require 'awesome_spawn'
        require_cmd! build_cmd
        target  = args[:target] || build_tgt
        srpm    = args[:srpm]
        scratch = args[:scratch] ? '--scratch' : ''
        cmd = "#{build_cmd} build #{scratch} #{target} #{srpm}"
        result = AwesomeSpawn.run(cmd)
        url = parse_url(result.output)
        raise url if result.exit_status != 0
        url
      end

      # Parse a koji build url from output
      def parse_url(output)
        task_info = output.lines.detect { |l| l =~ /Task info:.*/ }
        task_info ? task_info.split.last : ''
      end

      # def build_logs(url) # TODO
    end # module ClassMethods
  end # module KojiBuilder
end # module Polisher
