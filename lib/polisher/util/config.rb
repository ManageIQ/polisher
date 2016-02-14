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
    TARGETS = [['koji',     'polisher/targets/koji',    'Koji'],
               ['distgit',  'polisher/git/pkg',         'Git::Pkg'],
               ['rpm',      'polisher/rpm/spec',        'RPM::Requirement'],
               ['tags',     'polisher/util/tag_mapper', 'TagMapper'],
               ['profiles', 'polisher/util/profile',    'Profile']]

    def self.target_req_for(target)
      tgt = TARGETS.find { |tgt| tgt.first == target }
      return nil if tgt.nil?
      return tgt[1]
    end

    def self.target_class_str_for(target)
      tgt = TARGETS.find { |tgt| tgt.first == target }
      return nil if tgt.nil?
      return tgt[2]
    end

    def self.target_class_for(target)
      target_class_str_for(target).to_polisher_class
    end

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
      set_targets opts
    end

    def self.set_targets(targets)
      targets.each { |target, target_opts|
        set_target target, target_opts
      }
    end

    def self.set_target(target, target_opts)
      return unless target_opts
      #return unless TARGETS.find { |tgt| tgt.first == target }

      target_req = target_req_for(target)
      require target_req

      target_class   = target_class_for(target)
      sanitized_opts = target_opts.is_a?(Array) ?
                       {target => target_opts} : target_opts
      sanitized_opts.each { |k, v| target_class.send(k.intern, v) }
    end

    def self.get
      TARGETS.each do |target, req, polisher_class_str|
        require req
      end
    end
  end # class Config
end # module Polisher
