# Polisher Yum Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/conf_helpers'

module Polisher
  class Yum
    include ConfHelpers

    conf_attr :yum_cmd, '/usr/bin/yum'

    # Retrieve version of gem available in yum
    #
    # @param [String] name name of gem to loopup
    # @param [Callable] bl optional callback to invoke with version retrieved
    # @returns [String] version of gem in yum or nil if not found
    def self.version_for(name, &bl)
      require 'awesome_spawn'

      require_cmd! yum_cmd

      version = nil
      result  = AwesomeSpawn.run "#{yum_cmd} info rubygem-#{name}"
      out = result.output

      if out.include?("Version")
        version = out.lines.to_a.detect { |l| l =~ /^Version.*/ }
        version = version.split(':').last.strip
      end
      bl.call(:yum, name, [version]) unless bl.nil?
      version
    end
  end
end # module Polisher
