# Polisher Config Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'yaml'
require 'active_support'
require 'active_support/core_ext'
require 'polisher/util/core_ext'

module Polisher
  class Config
    CONF    = "#{ENV['HOME']}/.polisher/config"
    TARGETS = [['koji',    'polisher/targets/koji',    'Koji'],
               ['distgit', 'polisher/git/pkg',         'Git::Pkg'],
               ['rpm',     'polisher/rpm/spec',        'RPM::Requirement'],
               ['tags',    'polisher/util/tag_mapper', 'TagMapper']]

    def self.target_classes
      TARGETS.collect do |target, req, polisher_class_str|
        require req
        polisher_class_str.to_polisher_class
      end
    end

    def self.opts
      @opts ||=  File.exist?(CONF) ? YAML.load_file(CONF) : {}
    end

    def self.set
      TARGETS.each do |target, req, polisher_class_str|
        next unless opts[target]
        require req
        target_class = polisher_class_str.to_polisher_class
        opts[target].each { |k, v| target_class.send(k.intern, v) }
      end
    end

    def self.get
      TARGETS.each do |target, req, polisher_class_str|
        require req
      end
    end
  end # class Config
end # module Polisher
