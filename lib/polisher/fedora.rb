# Polisher Fedora Operations
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'curb'
require 'pkgwat'

module Polisher
  class Fedora
    PACKAGE_LIST = 'https://admin.fedoraproject.org/pkgdb/users/packages/'

    def self.gems_owned_by(user)
      curl = Curl::Easy.new("#{PACKAGE_LIST}}#{user}")
      curl.http_get
      packages = curl.body_str
      Nokogiri::HTML(packages).xpath("//a[@class='PackageName']").
                               select { |i| i.text =~ /rubygem-.*/ }.
                               collect { |i| i.text.gsub(/rubygem-/, '') }
    end

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
