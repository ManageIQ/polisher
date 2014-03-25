# Polisher User Represenation
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

module Polisher
  class User
    EMAIL = "#{ENV['USER']} <#{ENV['USERNAME']}@localhost.localdomain>"
    NAME  = "#{ENV['USER']}"

    # Return the currently configured email
    def self.email
      ENV['POLISHER_EMAIL'] || EMAIL
    end

    # Return the currently configured name
    def self.name
      ENV['POLISHER_NAME'] || NAME
    end
  end
end
