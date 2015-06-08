#!/usr/bin/ruby
# Polisher CLI Target Options
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

module Polisher
  module CLI
    def targets_conf
      { :check_fedora   => false,
        :check_git      => false,
        :check_koji     => false,
        :check_rhn      => false,
        :check_yum      => false,
        :check_bugzilla => false,
        :check_errata   => false,
        :check_bodhi    => false,
        :prefix         => nil }
    end

    def targets_options(option_parser)
      option_parser.on('-p', '--prefix prefix', 'Prefix to append to gem name') do |p|
        conf[:prefix] = p
      end

      option_parser.on('-f', '--[no-]fedora', 'Check fedora for packages') do |f|
        conf[:check_fedora] = f
      end

      option_parser.on('-g', '--git [url]', 'Check git for packages') do |g|
        conf[:check_git] = g || "git://pkgs.fedoraproject.org/"
      end

      option_parser.on('-k', '--koji [url]', 'Check koji for packages') do |k|
        conf[:check_koji] = k || true
      end

      option_parser.on('-t', '--koji-tag tag', 'Koji tag to query') do |t|
        conf[:koji_tag] = t
      end

      option_parser.on('-b', '--bodhi [url]', 'Check Bodhi for packages') do |r|
        conf[:check_bodhi] = r || 'https://admin.fedoraproject.org/updates/'
      end

      option_parser.on('--rhn [url]', 'Check RHN for packages') do |r|
        conf[:check_rhn] = r || 'TODO'
      end

      option_parser.on('-y', '--yum', 'Check yum for packages') do |y|
        conf[:check_yum] = y
      end

      option_parser.on('-b', '--bugzilla', 'Check bugzilla for bugs filed against package') do |b|
        conf[:check_bugzilla] = b
      end

      option_parser.on('-e', '--errata [url]', 'Check packages filed in errata') do |e|
        conf[:check_errata] = e || nil
      end
    end

    def set_targets(conf)
      targets = []
      require 'polisher/adaptors/version_checker'
      targets << Polisher::VersionChecker::GEM_TARGET    if conf[:check_gem]
      targets << Polisher::VersionChecker::KOJI_TARGET   if conf[:check_koji]
      targets << Polisher::VersionChecker::FEDORA_TARGET if conf[:check_fedora]
      targets << Polisher::VersionChecker::GIT_TARGET    if conf[:check_git]
      targets << Polisher::VersionChecker::YUM_TARGET    if conf[:check_yum]
      targets << Polisher::VersionChecker::BODHI_TARGET  if conf[:check_bodhi]
      targets  = Polisher::VersionChecker::ALL_TARGETS   if targets.empty?
      Polisher::VersionChecker.check targets
    end

    def configure_targets(conf)
      if conf[:check_koji]
        require 'polisher/targets/koji'
        Polisher::Koji.koji_url conf[:check_koji]   if conf[:check_koji].is_a?(String)
        Polisher::Koji.koji_tag conf[:koji_tag]     if conf[:koji_tag]
        Polisher::Koji.package_prefix conf[:prefix] if conf[:prefix]
      end

      # TODO other target config
    end
  end # module CLI
end # module Polisher
