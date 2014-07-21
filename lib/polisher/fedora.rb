# Polisher Fedora Operations
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/bodhi'
require 'polisher/component'
require 'open-uri'

module Polisher
  Component.verify("Fedora", "curb", "pkgwat", "nokogiri") do
    class Fedora
      PACKAGE_LIST_API = 'https://admin.fedoraproject.org/pkgdb/api'

      # Retrieve list of gems owned/co-maintained by the specified user
      #
      # @param [String] user Fedora username to lookup
      # @return [Array<String>] list of gems which the user owns/has access to
      def self.gems_owned_by(user)
        user_packages_url = "#{PACKAGE_LIST_API}/packager/package/#{user}"
        pkg_list = JSON.load(open(user_packages_url))

        pkg_owns = pkg_list['point of contact']
                   .select { |pkg| pkg['name'] =~ /^rubygem-/ }
                   .collect { |pkg| pkg['name'].gsub(/rubygem-/, '') }

        pkg_has_access = pkg_list['co-maintained']
                         .select { |pkg| pkg['name'] =~ /^rubygem-/ }
                         .collect { |pkg| pkg['name'].gsub(/rubygem-/, '') }

        pkg_owns + pkg_has_access

        # TODO: instantiate Polisher::Gem instances & return
      end

      # Retrieve list of the versions of the specified package in the various
      # Fedora releases.
      #
      # @param [String] name name of the package to lookup
      # @param [Callable] bl optional callback to invoke with versions retrieved
      # @return [Array<String>] list of versions in Fedora
      def self.versions_for(name, &bl)
        # simply dispatch to bodhi to get latest updates
        Polisher::Bodhi.versions_for name do |_target, pkg_name, versions|
          bl.call(:fedora, pkg_name, versions) unless bl.nil?
        end
      end
    end # class Fedora
  end # Component.verify("Fedora")
end # module Polisher
