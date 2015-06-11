# Polisher gem_dependency_checker cli util
#
# Licensed under the MIT license
# Copyright (C) 2015 Red Hat, Inc.
###########################################################

require 'optparse'

module Polisher
  module CLI
    def gem_dependency_checker_conf
      conf.merge!({:format => nil}).merge!(default_conf)
                                   .merge!(targets_conf)
                                   .merge!(sources_conf)
    end

    def gem_dependency_checker_options(option_parser)
      option_parser.on("--format val", 'Format which to render output') do |f|
        conf[:format] = f
      end
    end

    def gem_dependency_checker_option_parser
      OptionParser.new do |opts|
        default_options                opts
        sources_options                opts
        targets_options                opts
        gem_dependency_checker_options opts
      end
    end

    def header
      if @format == 'xml'
        '<dependencies>'
      elsif @format == 'json'
        '{'
      end
    end

    def footer
      if @format == 'xml'
        "</dependencies>"
      elsif @format == 'json'
        "}"
      end
    end

    def print_header
      print header
    end

    def print_footer
      print footer
    end

    def print_dep(dep, tgt, versions)
      print pretty_tgt(dep, tgt, versions)
    end

    def print_gem_deps(gem)
      gem.versions(:recursive => true,
                   :dev_deps  => conf[:devel_deps]) do |tgt, dep, versions|
        print_dep(dep, tgt, versions)
      end
    end

    def print_gemfile_deps(gemfile)
      gemfile.dependency_versions :recursive => true,
                                  :dev_deps  => conf[:devel_deps] do |tgt, dep, versions|
        print_dep(dep, tgt, versions)
      end
    end

    def print_deps(conf)
      if conf_gem?
        print_gem_deps(conf_source)

      elsif conf_gemfile?
        print_gemfile_deps(conf_source)
      end

      puts last_dep # XXX
    end
  end # module CLI
end # module Polisher
