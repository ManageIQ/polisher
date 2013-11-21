# Polisher Yum Operations
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'pkgwat'

module Polisher
  class Yum
    YUM_CMD = '/usr/bin/yum'

    def self.version_for(name)
      out=`#{YUM_CMD} info rubygem-#{name}`
      return nil if out =~ /.*No matching Packages.*/
      version = out.lines.to_a.find { |l| l =~ /^Version.*/ }
      version.split(':').last.strip
    end
  end
end
