# Polisher Targets
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/targets/apt'
require 'polisher/targets/bodhi'
require 'polisher/targets/bugzilla'
require 'polisher/targets/errata'
require 'polisher/targets/fedora'
require 'polisher/targets/koji'
require 'polisher/targets/rhn'
require 'polisher/targets/yum'

module Polisher
  def self.target(name)
    case name
    when 'apt'
      Polisher::Apt
    when 'bodhi'
      Polisher::Bodhi
    when 'bugzilla'
      Polisher::Bugzilla
    when 'errata'
      Polisher::Errata
    when 'fedora'
      Polisher::Fedora
    when 'koji'
      Polisher::Koji
    when 'rhn'
      Polisher::RHN
    when 'yum'
      Polisher::Yum
    end
  end
end # module Polisher
