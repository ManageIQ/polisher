#!/usr/bin/ruby
# Polisher CLI
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def self.conf
      @conf ||= {}
    end

    def conf
      CLI.conf
    end
  end # mdoule CLI
end
