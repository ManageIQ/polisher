# Polisher Core Ruby Extensions
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/config'

module ConfHelpers
  module ClassMethods
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
        instance_variable_set(nvar, default)    unless current
        instance_variable_set(nvar, ENV[envk])  if ENV.key?(envk)
        # TODO also allow vars to be able to be set from a conf file
        self.instance_variable_set(nvar, args.first) unless args.empty?
        self.instance_variable_get(nvar)
      end

      self.send(:define_method, name) do
        self.class.send(name)
      end
    end

    def cmd_available?(cmd)
      File.exist?(cmd) && File.executable?(cmd)
    end

    def require_cmd!(cmd)
      raise "command #{cmd} not available" unless cmd_available?(cmd)
    end # module ClassMethods
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def require_cmd!(cmd)
    self.class.require_cmd!(cmd)
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
    matchers = Polisher::RPM::Spec::FILE_MACRO_MATCHERS
    replacements = Polisher::RPM::Spec::FILE_MACRO_REPLACEMENTS
    f = matchers.inject(self) { |file, matcher| file.gsub(matcher, '') }
    f = replacements.keys.inject(f) { |file, r| file.gsub(Regexp.new(r), replacements[r]) }
    f
  end

  # Replace all occurrances of non-rpm macro strings in self
  # with their macro correspondences
  def rpmize
    require 'polisher/rpm/spec'
    matchers = Polisher::RPM::Spec::FILE_MACRO_MATCHERS
    replacements = Polisher::RPM::Spec::FILE_MACRO_REPLACEMENTS.invert
    f = replacements.keys.inject(self) { |file, r| file.gsub(r, replacements[r]) }

    special = (matchers + replacements.values).any? { |matcher| f =~ /^#{matcher}.*/ }
    f = special ? f : "%{gem_instdir}/#{f}"
    f
  end
end
