# Mechanism to cache gems
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'fileutils'

module Polisher
  class GemCache
    DIR = "#{ENV['HOME']}/.polisher/gems"

    def self.create!
      FileUtils.mkdir_p(DIR) unless File.directory?(DIR)
    end

    def self.clear!
      FileUtils.rm_rf(DIR)
    end

    def self.path_for(name, version)
      path = "#{DIR}/#{name}-#{version}.gem"
    end

    def self.get(name, version)
      path = path_for(name, version)
      File.exists?(path) ? File.read(path) : nil
    end

    def self.set(name, version, gem)
      self.create!
      File.write(path_for(name, version), gem)
    end
  end # class GemCache
end # module Polisher
