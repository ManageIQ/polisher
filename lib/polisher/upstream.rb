# Polisher Upstream Operations
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'polisher/gem'
require 'polisher/gemfile'

module Polisher
  class Upstream
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
