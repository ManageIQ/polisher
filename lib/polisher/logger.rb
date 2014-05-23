# Polisher Logging Module
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

module Polisher
  module Logging
    # This is the magical bit that gets mixed into your classes
    def logger
      Logging.logger
    end

    # Set the log level
    def self.level=(level)
      logger.level = Logger.const_get(level.to_s.upcase)
    end

    # Global, memoized, lazy initialized instance of a logger
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end
  end # module Logging
end # module Polisher
