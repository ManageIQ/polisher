# Polisher Upstream Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/gemfile'
require 'polisher/util/core_ext'

module Polisher
  class Upstream
    # Parse the specified upstream source, automatically
    # dispatches to correct upstream parser depending on
    # format of specified source
    #
    # @returns instance of class representing parsed source
    def self.parse(source)
      if source.gem?
        Polisher::Gem.parse(:gem => source)
      elsif source.gemspec?
        Polisher::Gem.parse(:gemspec => source)
      elsif source.gemfile?
        Polisher::Gemfile.parse(source)
      end
    end
  end
end
