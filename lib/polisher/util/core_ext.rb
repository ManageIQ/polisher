# Polisher Core Ruby Extensions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

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
    require 'polisher/rpm/spec'
    matchers = Polisher::RPM::Spec::FILE_MACRO_MATCHERS
    replacements = Polisher::RPM::Spec::FILE_MACRO_REPLACEMENTS
    f = matchers.inject(self) { |file, matcher| file.gsub(matcher, '') }
    f = replacements.keys.inject(f) { |file, r| file.gsub(Regexp.new(r), replacements[r]) }
    f
  end

  # Replace all occurrances of non-rpm macro strings in self with
  # their macro correspondences and add %doc macro or lib's bin path
  # if necessary
  def rpmize
    require 'polisher/gem'
    require 'polisher/rpm/spec'
    matchers = Polisher::RPM::Spec::FILE_MACRO_MATCHERS
    replacements = Polisher::RPM::Spec::FILE_MACRO_REPLACEMENTS.invert
    f = replacements.keys.inject(self) { |file, r| file.gsub(r, replacements[r]) }

    special = (matchers + replacements.values).any? { |matcher| f =~ /^#{matcher}.*/ }
    f = special ? f : "%{gem_instdir}/#{f}"

    include_lib_bin = (f =~ /\A%{_bindir}.*/)
    f = include_lib_bin ? "#{f}\n%{gem_instdir}/#{self}" : f

    doc_file        = Polisher::Gem.doc_file?(self) ||
    license_file    = Polisher::Gem.license_file?(self)
    mark_as_doc     = doc_file && !(self =~ /%doc .*/)
    mark_as_license = license_file && !(self =~ /%license .*/)
    f = mark_as_doc     ? "%doc #{f}" : f
    f = mark_as_license ? "%license #{f}" : f
    f
  end

  def to_polisher_class
    "Polisher::#{self}".constantize
  end
end
