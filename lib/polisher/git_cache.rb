# Mechanism to cache git repos
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'fileutils'

module Polisher
  class GitCache
    DIR = "#{ENV['HOME']}/.polisher/git"

    def self.create!
      FileUtils.mkdir_p(DIR) unless File.directory?(DIR)
    end

    def self.clear!
      FileUtils.rm_rf(DIR)
    end

    def self.path_for(id)
      self.create!
      "#{DIR}/#{id.gsub(/[:\/]/, '')}"
    end
  end # class GemCache
end # module Polisher
