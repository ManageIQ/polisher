# Polisher Spec Path Helpers
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

def spec_support_dir
  @spec_support_dir ||= File.expand_path(File.dirname(__FILE__))
end

def spec_dir
  @spec_dir ||= File.expand_path(File.join(spec_support_dir, '..'))
end

def lib_dir
  @lib_dir ||= File.expand_path(File.join(spec_dir, '..'))
end

def data_dir
  @data_dir ||= File.expand_path(File.join(spec_dir, 'data'))
end
