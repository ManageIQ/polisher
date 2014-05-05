# Polisher Fedora Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/bodhi'
require 'polisher/component'

module Polisher
  Component.verify("Fedora", "curb", "pkgwat", "nokogiri") do
    class Fedora
      PACKAGE_LIST = 'https://admin.fedoraproject.org/pkgdb/users/packages/'

      def self.client
        @client ||= Curl::Easy.new
      end

      # Retrieve list of gems owned by the specified user
      #
      # @param [String] user Fedora username to lookup
      # @return [Array<String>] list of gems which the user owns/has access to
      def self.gems_owned_by(user)
        client.url = "#{PACKAGE_LIST}#{user}"
        client.http_get
        packages = client.body_str
        # TODO instantiate Polisher::Gem instances & return
        Nokogiri::HTML(packages).xpath("//a[@class='PackageName']").
                                 select { |i| i.text =~ /rubygem-.*/ }.
                                 collect { |i| i.text.gsub(/rubygem-/, '') }
      end

      # Retrieve list of the versions of the specified package in the various
      # Fedora releases.
      #
      # @param [String] name name of the package to lookup
      # @param [Callable] bl optional callback to invoke with versions retrieved
      # @return [Array<String>] list of versions in Fedora
      def self.versions_for(name, &bl)
        # simply dispatch to bodhi to get latest updates
        Polisher::Bodhi.versions_for name do |target,name,versions|
          bl.call(:fedora, name, versions) unless(bl.nil?)
        end
      end
    end # class Fedora
  end # Component.verify("Fedora")
end # module Polisher
