# Polisher Fedora Operations
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'curb'
require 'pkgwat'

module Polisher
  class Fedora
    PACKAGE_LIST = 'https://admin.fedoraproject.org/pkgdb/users/packages/'

    # Retrieve list of gems owned by the specified user
    #
    # @param [String] user Fedora username to lookup
    # @return [Array<String>] list of gems which the user owns/has access to
    def self.gems_owned_by(user)
      curl = Curl::Easy.new("#{PACKAGE_LIST}}#{user}")
      curl.http_get
      packages = curl.body_str
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
      # XXX bug w/ python-pkgwat, some html content
      # is being returned w/ versions, need to look into
      versions = Pkgwat.get_versions(name)
      versions.reject! { |pkg| pkg['stable_version'] == "None" }
      versions = versions.collect { |pkg| pkg['stable_version'] }
      bl.call(:fedora, name, versions) unless(bl.nil?) 
      versions
    end
  end # class Fedora
end # module Polisher
