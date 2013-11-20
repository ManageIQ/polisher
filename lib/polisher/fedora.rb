# Polisher Fedora Operations
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'curb'

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
  end # class Fedora
end # module Polisher
