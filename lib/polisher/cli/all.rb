#!/usr/bin/ruby
# Polisher CLI
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'polisher/cli/default'
require 'polisher/cli/sources'
require 'polisher/cli/targets'
require 'polisher/cli/specifier'
require 'polisher/cli/format'
require 'polisher/cli/fedora'
require 'polisher/cli/conf'
require 'polisher/cli/paths'
require 'polisher/cli/status'
require 'polisher/cli/deps'
require 'polisher/cli/profiles'
require 'polisher/cli/cross_ref'
require 'polisher/cli/updater'

module Polisher
  module CLI
    #def self.included(base)
    #  base.extend(ClassMethods)
    #end
  end # module CLI
end # module Polisher
