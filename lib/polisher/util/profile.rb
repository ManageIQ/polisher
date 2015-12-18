# Polisher Profiles
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.

require "active_support/core_ext/hash/except"

require 'polisher/util/config'
require 'polisher/util/conf_helpers'

module Polisher
  class Profile
    include ConfHelpers

    CONF = "#{ENV['HOME']}/.polisher/profiles"

    def self.conf_profiles
      @conf_profiles ||=  File.exist?(CONF) ? YAML.load_file(CONF) : {}
    end

    conf_attr :profiles
    def self.profiles(profiles=nil)
      @profiles ||= profiles
      profiles.each { |profile|
        next unless conf_profiles[profile]
        base = conf_profiles[profile]['inherits']
        profiles([base].flatten) if base
        Config.set_targets conf_profiles[profile].except('inherits')
      } unless profiles.nil?
      @profiles
    end
  end # class Profile
end # module Polisher
