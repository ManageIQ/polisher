# Version Checker Target Loader Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'active_support'
require 'active_support/core_ext'

module Polisher
  module CheckerLoader
    # Dir which target checkers reside
    def target_dir
      @target_dir ||= File.expand_path(File.join(File.dirname(__FILE__), '/version_checker'))
    end

    # Targets to check
    def targets
      @targets ||= Dir.glob(File.join(target_dir, '*.rb'))
                      .collect { |t| t.gsub("#{target_dir}/", '').gsub('.rb', '').intern }
    end

    # Mixin module corresponding to target
    def target_module(target)
      "Polisher::#{target.to_s.camelcase}VersionChecker".constantize
    end

    # Target corresponding to mixin module
    def module_target(mod)
      mod.to_s.gsub('Polisher::', '').gsub('VersionChecker', '').underscore.intern
    end

    # Mixed in method to check target
    def target_method(target)
      "#{target}_versions"
    end

    # Load specified target
    def load_target(target)
      raise ArgumentError, target unless targets.include?(target)

      require "polisher/adaptors/version_checker/#{target}"

      tm = target_module(target)
      @target_modules ||= []
      @target_modules << tm
      include tm
    end

    # Load all targets
    def load_targets
      targets.each { |t| load_target t }
      targets
    end
    alias :all_targets :load_targets

    # Return modules marked as default
    def default_modules
      @target_modules ||= []
      @target_modules.select { |tm| tm.default? }
    end

    # Return targets marked as default
    def default_targets
      default_modules.collect { |m| module_target(m) }
    end

    # Enable the specified target(s) in the list of target to check
    def check(*target)
      @check_list ||= []
      target.flatten.each { |t| @check_list << t }
    end

    # Return bool indicating if target should be checked
    def should_check?(target)
      @check_list ||= Array.new(default_targets)
      @check_list.include?(target)
    end
  end # module CheckerLoader
end
