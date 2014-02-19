# Polisher Core Ruby Extensions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/rpmspec'

class Object
  def eigenclass
    class << self
      self
    end
  end
end

module ConfHelpers
  def conf_attr(name, default=nil)
    self.send(:define_singleton_method, name) do |*args|
      nvar = "@#{name}".intern
      current = self.instance_variable_get(nvar)
      self.instance_variable_set(nvar, default)    unless current
      self.instance_variable_set(nvar, args.first) unless args.empty?
      self.instance_variable_get(nvar)
    end

    self.send(:define_method, name) do
      self.class.send(name)
    end
  end
end

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
