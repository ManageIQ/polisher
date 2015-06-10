# Polisher Targets
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/apt'
require 'polisher/bodhi'
require 'polisher/bugzilla'
require 'polisher/errata'
require 'polisher/fedora'
require 'polisher/koji'
require 'polisher/rhn'
require 'polisher/yum'

module Polisher
module Target
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
end # module Target
end # module Polisher
