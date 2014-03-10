# Polisher Core Ruby Extensions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module ConfHelpers
  # Defines a 'config attribute' or attribute on the class
  # which this is defined in. Accessors to the single shared
  # attribute will be added to the class as well as instances
  # of the class. Specify the default value with the attr name
  # or via an env variable
  #
  # @example
  #   class Custom
  #     extend ConfHelpers
  #     conf_attr :data_dir, '/etc/'
  #   end
  #   Custom.data_dir # => '/etc/'
  #   ENV['POLISHER_DATA_DIR'] = '/usr/'
  #   Custom.data_dir # => '/usr/'
  #   Custom.data_dir == Custom.new.data_dir # => true
  #
  def conf_attr(name, default=nil)
    self.send(:define_singleton_method, name) do |*args|
      nvar = "@#{name}".intern
      current = self.instance_variable_get(nvar)
      envk    = "POLISHER_#{name.to_s.upcase}"
      self.instance_variable_set(nvar, default)    unless current
      self.instance_variable_set(ENV[envk])        if ENV.has_key?(envk)
      # TODO also allow vars to be able to be set from a conf file
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
    require 'polisher/rpm/spec'
    fmm = Polisher::RPM::Spec::FILE_MACRO_MATCHERS
    fmr = Polisher::RPM::Spec::FILE_MACRO_REPLACEMENTS
    f = fmm.inject(self) { |file, matcher| file.gsub(matcher, '') }
    f = fmr.keys.inject(f) { |file, r| file.gsub(Regexp.new(r), fmr[r]) }
    f
  end

  # Replace all occurrances of non-rpm macro strings in self
  # with their macro correspondences
  def rpmize
    require 'polisher/rpm/spec'
    fmr = Polisher::RPM::Spec::FILE_MACRO_REPLACEMENTS.invert
    fmr.keys.inject(self) { |file, r| file.gsub(r, fmr[r]) }
  end
end
