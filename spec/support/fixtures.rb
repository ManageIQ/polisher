# Polisher Spec Fixtures
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

# TODO parameterize fixtures w/ defaults loaded from yaml

Dir.glob("#{spec_dir}/fixtures/*.rb") { |mod| require mod }
