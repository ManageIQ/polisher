# Polisher Gem Diff Mixin
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'fileutils'
require 'polisher/git/repo'

module Polisher
  module GemDiff
    # Return diff of content in this gem against other
    def diff(other)
      require 'awesome_spawn'

      require_cmd! diff_cmd
      out = nil

      begin
        this_dir  = unpack
        other_dir = if other.is_a?(Polisher::Gem)
                      other.unpack
                    elsif other.is_a?(Polisher::Git::Repo) 
                      other.path   
                    else
                      other
                    end

        result = AwesomeSpawn.run("#{diff_cmd} -r #{this_dir} #{other_dir}")
        out = result.output.gsub("#{this_dir}", 'a').gsub("#{other_dir}", 'b')
      ensure
        FileUtils.rm_rf this_dir  unless this_dir.nil?
        FileUtils.rm_rf other_dir unless  other_dir.nil? ||
                                         !other.is_a?(Polisher::Gem)
      end

      out
    end
  end # module GemDiff
end # module Polisher
