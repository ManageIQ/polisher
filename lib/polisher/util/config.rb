# Polisher Config Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'yaml'
require 'active_support'
require 'active_support/core_ext'

module Polisher
  class Config
    CONF    = "#{ENV['HOME']}/.polisher/config"
    TARGETS = [['koji',    'polisher/koji',    'Koji'],
               ['distgit', 'polisher/git/pkg', 'Git::Pkg'],
               ['rpm',     'polisher/rpm/spec', 'RPM::Requirement'],
               ['tags',    'polisher/tag_mapper', 'TagMapper']]

    def self.opts
      @opts ||=  File.exist?(CONF) ? YAML.load_file(CONF) : {}
    end

    def self.set
      TARGETS.each do |target, req, polisher_class|
        next unless opts[target]
        require req
        target_class = "Polisher::#{polisher_class}".constantize
        opts[target].each { |k, v| target_class.send(k.intern, v) }
      end
    end
  end # class Config
end # module Polisher
