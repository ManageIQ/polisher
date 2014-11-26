# Polisher Gemfile Parser Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module GemfileParser
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Parse the specified gemfile & return new Gemfile instance from metadata
      #
      # @param [String] path to gemfile to parse
      # @return [Polisher::Gemfile] gemfile instantiated from parsed metadata
      def parse(path, args = {})
        require 'bundler'

        groups = args[:groups]

        definition = nil
        path, gemfile = File.split(path)
        Dir.chdir(path) do
          begin
            definition = Bundler::Definition.build(gemfile, nil, false)
          rescue Bundler::GemfileNotFound
            raise ArgumentError, "invalid gemfile: #{path}"
          end
        end

        metadata = {}
        metadata[:deps] = definition.dependencies.select do |d|
          groups.nil? || groups.empty? ||                  # groups not specified
          groups.any? { |g| d.groups.include?(g.intern) }  # dep in any group
        end

        metadata[:dev_deps] = [] # TODO
        metadata[:definition] = definition

        new metadata
      end
    end # module ClassMethods
  end # module GemfileParser
end # module Polisher
