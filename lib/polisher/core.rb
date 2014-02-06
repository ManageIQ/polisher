# Polisher Core Ruby Extensions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/rpmspec'

class String
  # Return bool indicating if self is a path to a gem
  def gem?
    File.extname(self) == ".gem"
  end

  # Return bool indicating if self is a path to a gemspec
  def gemspec?
    File.extname(self) == ".gemspec"
  end

  # Return bool indicating if self is a path to a Gemfile
  def gemfile?
    File.basename(self) == "Gemfile"
  end

  # Remove and replace all occurances of rpm macros in self with non-rpm
  # macro correspondents. If no rpm macro is specified macro will
  # simply be removed
  def unrpmize
    fmm = Polisher::RPMSpec::FILE_MACRO_MATCHERS
    fmr = Polisher::RPMSpec::FILE_MACRO_REPLACEMENTS
    f = fmm.inject(self) { |file, matcher| file.gsub(matcher, '') }
    f = fmr.keys.inject(f) { |file, r| file.gsub(Regexp.new(r), fmr[r]) }
    f
  end

  # Replace all occurrances of non-rpm macro strings in self
  # with their macro correspondences
  def rpmize
    fmr = Polisher::RPMSpec::FILE_MACRO_REPLACEMENTS.invert
    fmr.keys.inject(self) { |file, r| file.gsub(r, fmr[r]) }
  end
end
