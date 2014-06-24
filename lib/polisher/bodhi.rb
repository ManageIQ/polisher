# Polisher Bodhi Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

# XXX issue w/ retreiving packages from pkgwat causing sporadic issues:
# https://github.com/fedora-infra/fedora-packages/issues/55
require 'polisher/component'

module Polisher
  # fedora pkgwat provides a frontend to bodhi
  Component.verify("Bodhi", "pkgwat") do
    class Bodhi
      def self.versions_for(name, &bl)
        versions = Pkgwat.get_updates("rubygem-#{name}", 'all', 'all').
                     select  { |update| update['stable_version']  != 'None' }.
                     collect { |update| update['stable_version'] }
        bl.call(:bodhi, name, versions) unless(bl.nil?)
        versions
      end
    end
  end
end
