# Polisher Spec RSpec Integration
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/util/gem_cache'

RSpec.configure do |config|
  config.include Polisher::Test

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.after do
    Polisher::GemCache.clear!
  end
end
