# Polisher Spec Coveralls Integration
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

begin
  require 'coveralls'
  Coveralls.wear!
rescue LoadError
end
