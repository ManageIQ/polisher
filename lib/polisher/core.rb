# Polisher Core Ruby Extensions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/rpmspec'

class String
  def gem?
    File.extname(self) == ".gem"
  end

  def gemspec?
    File.extname(self) == ".gemspec"
  end

  def gemfile?
    File.basename(self) == "Gemfile"
  end

  def unrpmize
    fmm = Polisher::RPMSpec::FILE_MACRO_MATCHERS
    fmr = Polisher::RPMSpec::FILE_MACRO_REPLACEMENTS
    f = fmm.inject(self) { |file, matcher| file.gsub(matcher, '') }
    f = fmr.keys.inject(f) { |file, r| file.gsub(Regexp.new(r), fmr[r]) }
    f
  end

  def rpmize
    fmr = Polisher::RPMSpec::FILE_MACRO_REPLACEMENTS.invert
    fmr.keys.inject(self) { |file, r| file.gsub(r, fmr[r]) }
  end
end
