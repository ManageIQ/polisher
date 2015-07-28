# Polisher Spec VCR Integration
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = false
end
