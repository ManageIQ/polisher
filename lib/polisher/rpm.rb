# RPM Module
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher
  module RPM
    # Use rpmdev-packager if it's available
    def self.packager
      require 'awesome_spawn'
      @packager ||= AwesomeSpawn.run('/usr/bin/rpmdev-packager').output.chop
    rescue AwesomeSpawn::NoSuchFileError
    end

    # Return the currently configured author
    def self.current_author
      ENV['POLISHER_AUTHOR'] || packager || Spec::AUTHOR
    end
  end # module RPM
end # module Polisher
