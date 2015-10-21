# Polisher Gem Files Mixin
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'pathname'
require 'rubygems/installer'
require 'active_support'
require 'active_support/core_ext'

module Polisher
  module GemFiles
    # Common files shipped in gems that we should ignore
    IGNORE_FILES = ['.gemtest', '.gitignore', '.travis.yml',
                    /.*.gemspec/, /Gemfile.*/, 'Rakefile',
                    /rspec.*/, '.yardopts', '.rvmrc']

    # Critical runtime files that are necessary for the gem to run
    RUNTIME_FILES = [/\Alib.*/, /\Abin.*/, /\Aapp.*/, /\Avendor.*/]

    # License files
    LICENSE_FILES = [/\/?MIT/, /\/?GPLv[0-9]+/, /\/?.*LICEN(C|S)E/, /\/?COPYING/]

    # Common files shipped in gems considered doc
    DOC_FILES = [/\/?CHANGELOG.*/i, /\/?CONTRIBUTING.*/i, /\/?CONTRIBUTORS.*/i,
                 /\/?README.*/i, /\/?History.*/i, /\/?Release.*/i, /\/?doc(\/.*)?/]

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Return bool indicating if the specified file is on the IGNORE_FILES list
      def ignorable_file?(file)
        IGNORE_FILES.any? do |ignore|
          ignore.is_a?(Regexp) ? ignore.match(file) : ignore == file
        end
      end

      # Return bool indicating if the specified file in on the RUNTIME_FILES list
      def runtime_file?(file)
        RUNTIME_FILES.any? do |runtime|
          runtime.is_a?(Regexp) ? runtime.match(file) : runtime == file
        end
      end

      # Return bool indicating if the specified file is on the LICENSE_FILES list
      def license_file?(file)
        LICENSE_FILES.any? do |license|
          license.is_a?(Regexp) ? license.match(file) : license == file
        end
      end

      # Return bool indicating if the specified file is on the DOC_FILES list
      def doc_file?(file)
        DOC_FILES.any? do |doc|
          doc.is_a?(Regexp) ? doc.match(file) : doc == file
        end
      end
    end # module ClassMethods

    # Return bool indicating if spec file satisfies any file in gem
    def has_file_satisfied_by?(spec_file)
      file_paths.any? { |gem_file| RPM::Spec.file_satisfies?(spec_file, gem_file) }
    end

    # Unpack files & return unpacked directory
    #
    # If block is specified, it will be invoked
    # with directory after which directory will be removed
    def unpack(&bl)
      dir = nil
      pkg = ::Gem::Installer.new gem_path, :unpack => true

      if bl
        Dir.mktmpdir do |tmpdir|
          pkg.unpack tmpdir
          bl.call tmpdir
        end
      else
        dir = Dir.mktmpdir
        pkg.unpack dir
      end

      dir
    end

    # Iterate over each file in gem invoking block with path
    def each_file(&bl)
      unpack do |dir|
        Pathname.new(dir).find do |path|
          next if path.to_s == dir.to_s
          pathstr = path.to_s.gsub("#{dir}/", '')
          bl.call pathstr unless pathstr.blank?
        end
      end
    end

    # Retrieve the list of paths to files in the gem
    #
    # @return [Array<String>] list of files in the gem
    def file_paths
      @file_paths ||= begin
        files = []
        each_file do |path|
          files << path
        end
        files
      end
    end
  end # module GemFiles
end # module Polisher
