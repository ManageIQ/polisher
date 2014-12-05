# Polisher Gem Retriever Mixin
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/util/gem_cache'

module Polisher
  module GemRetriever
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Return handler to internal curl helper
      def client
        require 'curb'

        @client ||= Curl::Easy.new
      end

      # Download the specified gem and return the binary file contents as a string
      #
      # @return [String] binary gem contents
      def download_gem(name, version)
        cached = GemCache.get(name, version)
        return cached unless cached.nil?

        client.url = "https://rubygems.org/gems/#{name}-#{version}.gem"
        client.follow_location = true
        client.http_get
        gemf = client.body_str

        GemCache.set(name, version, gemf)
        gemf
      end

      # Download the specified gem / version from rubygems and
      # return instance of Polisher::Gem class corresponding to it
      def from_rubygems(name, version)
        download_gem name, version
        from_gem downloaded_gem_path(name, version)
      end

      # Returns path to downloaded gem
      #
      # @return [String] path to downloaded gem
      def downloaded_gem_path(name, version)
        # ensure gem is downloaded
        download_gem name, version
        GemCache.path_for(name, version)
      end

      # Retrieve gem metadata and contents from rubygems.org
      #
      # @param [String] name string name of gem to retrieve
      # @return [Polisher::Gem] representation of gem
      def retrieve(name)
        require 'curb'

        gem_json_path = "https://rubygems.org/api/v1/gems/#{name}.json"
        spec = Curl::Easy.http_get(gem_json_path).body_str
        gem  = parse spec
        gem
      end
    end # module ClassMethods

    # Download the local gem and return it as a string
    def download_gem
      self.class.download_gem @name, @version
    end

    # Return path to downloaded gem
    def downloaded_gem_path
      self.class.downloaded_gem_path @name, @version
    end
  end # module GemRetriever
end # module Polisher
