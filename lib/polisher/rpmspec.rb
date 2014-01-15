# Polisher RPM Spec Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'gem2rpm'
require 'active_support/core_ext'

require 'polisher/core'

module Polisher
  class RPMSpec
    AUTHOR = "#{ENV['USER']} <#{ENV['USER']}@localhost.localdomain>"

    COMMENT_MATCHER             = /^\s*#.*/
    GEM_NAME_MATCHER            = /^%global\s*gem_name\s(.*)$/
    SPEC_NAME_MATCHER           = /^Name:\s*rubygem-(.*)$/
    SPEC_VERSION_MATCHER        = /^Version:\s*(.*)$/
    SPEC_RELEASE_MATCHER        = /^Release:\s*(.*)$/
    SPEC_REQUIRES_MATCHER       = /^Requires:\s*(.*)$/
    SPEC_BUILD_REQUIRES_MATCHER = /^BuildRequires:\s*(.*)$/
    SPEC_GEM_REQ_MATCHER        = /^.*\s*rubygem\((.*)\)(\s*(.*))?$/
    SPEC_SUBPACKAGE_MATCHER     = /^%package\s(.*)$/
    SPEC_CHANGELOG_MATCHER      = /^%changelog$/
    SPEC_FILES_MATCHER          = /^%files$/
    SPEC_SUBPKG_FILES_MATCHER   = /^%files\s*(.*)$/
    
    FILE_MACRO_MATCHERS         =
      [/^%doc\s/,     /^%config\s/,  /^%attr\s/,
       /^%verify\s/,  /^%docdir.*/,  /^%dir\s/,
       /^%defattr.*/, /^%exclude\s/, /^%{gem_instdir}/]
    
    FILE_MACRO_REPLACEMENTS =
      {"%{_bindir}"    => '/bin',
       "%{gem_libdir}" => '/lib'}

    attr_accessor :metadata

    def initialize(metadata={})
      @metadata = metadata
    end

    # Dispatch all missing methods to lookup calls in rpm spec metadata
    def method_missing(method, *args, &block)
      # proxy to metadata
      if @metadata.has_key?(method)
        @metadata[method]

      else
        super(method, *args, &block)
      end
    end

    # Parse the specified rpm spec and return new RPMSpec instance from metadata
    #
    # @param [String] string contents of spec to parse
    # @return [Polisher::RPMSpec] spec instantiated from rpmspec metadata
    def self.parse(spec)
      in_subpackage = false
      in_changelog  = false
      in_files      = false
      subpkg_name   = nil
      meta = {:contents => spec}
      spec.each_line { |l|
        if l =~ COMMENT_MATCHER
          ;
    
        # TODO support optional gem prefix
        elsif l =~ GEM_NAME_MATCHER
          meta[:gem_name] = $1.strip
          meta[:gem_name] = $1.strip
    
        elsif l =~ SPEC_NAME_MATCHER &&
              $1.strip != "%{gem_name}"
          meta[:gem_name] = $1.strip
    
        elsif l =~ SPEC_VERSION_MATCHER
          meta[:version] = $1.strip
    
        elsif l =~ SPEC_RELEASE_MATCHER
          meta[:release] = $1.strip
    
        elsif l =~ SPEC_SUBPACKAGE_MATCHER
          subpkg_name = $1.strip
          in_subpackage = true
    
        elsif l =~ SPEC_REQUIRES_MATCHER &&
              !in_subpackage
          meta[:requires] ||= []
          meta[:requires] << $1.strip
    
        elsif l =~ SPEC_BUILD_REQUIRES_MATCHER &&
              !in_subpackage
          meta[:build_requires] ||= []
          meta[:build_requires] << $1.strip
    
        elsif l =~ SPEC_CHANGELOG_MATCHER
          in_changelog = true
    
        elsif l =~ SPEC_FILES_MATCHER
          subpkg_name = nil
          in_files = true
    
        elsif l =~ SPEC_SUBPKG_FILES_MATCHER
          subpkg_name = $1.strip
          in_files = true
    
        elsif in_changelog
          meta[:changelog] ||= ""
          meta[:changelog] << l
    
        elsif in_files
          tgt = subpkg_name.nil? ? meta[:gem_name] : subpkg_name
          meta[:files] ||= {}
          meta[:files][tgt] ||= []
    
          sl = l.strip.unrpmize
          meta[:files][tgt] << sl unless sl.blank?
        end
      }
    
      meta[:changelog_entries] = meta[:changelog] ?
                                 meta[:changelog].split("\n\n") : []
      meta[:changelog_entries].collect! { |c| c.strip }.compact!

      self.new meta
    end

    # Update RPMSpec metadata to new gem
    #
    # @param [Polisher::Gem] new_source new gem to update rpmspec to
    def update_to(new_source)
      update_deps_from(new_source)
      update_files_from(new_source)
      update_metadata_from(new_source)
    end

    private

    def update_deps_from(new_source)
      non_gem_requires    = []
      non_gem_brequires   = []
      extra_gem_requires  = []
      extra_gem_brequires = []

      @metadata[:requires] ||= []
      @metadata[:requires].each { |r|
        if r !~ SPEC_GEM_REQ_MATCHER
          non_gem_requires << r
        elsif !new_source.deps.any? { |d| d.name == $1 }
          extra_gem_requires << r
        #else
        #  spec_version = $2
        end
      }

      @metadata[:build_requires] ||= []
      @metadata[:build_requires].each { |r|
        if r !~ SPEC_GEM_REQ_MATCHER
          non_gem_brequires << r
        elsif !new_source.deps.any? { |d| d.name == $1 }
          extra_gem_brequires << r
        #else
        #  spec_version = $2
        end
      }

      # TODO detect if req is same as @version, swap out w/ %{version} macro ?

      @metadata[:requires] =
        non_gem_requires + extra_gem_requires +
        new_source.deps.collect { |r|
          r.requirement.to_s.split(',').collect { |req|
           expanded = Gem2Rpm::Helpers.expand_requirement [req.split]
           expanded.collect { |e|
             "rubygem(#{r.name}) #{e.first} #{e.last}"
           }
          }
        }.flatten

      @metadata[:build_requires] =
        non_gem_brequires + extra_gem_brequires +
        new_source.dev_deps.collect { |r|
          r.requirement.to_s.split(',').collect { |req|
            "rubygem(#{r.name}) #{req}"
          }
        }.flatten
    end

    def update_files_from(new_source)
      to_add = new_source.files
      @metadata[:files] ||= {}
      @metadata[:files].each { |pkg,spec_files|
        (new_source.files & to_add).each { |gem_file|
          # skip files already included in spec or in dir in spec
          has_file = spec_files.any? { |sf|
                       gem_file.gsub(sf,'') != gem_file
                     }

          to_add.delete(gem_file)
          to_add << gem_file.rpmize if !has_file
        }
      }

      @metadata[:new_files] = to_add
    end

    def update_metadata_from(new_source)
      # update to new version
      @metadata[:version] = new_source.version

      # better release updating ?
      release = "1%{?dist}"
      @metadata[:release] = release

      # add changelog entry
      changelog_entry = <<EOS
* #{Time.now.strftime("%a %b %d %Y")} #{AUTHOR} - #{$version}-#{release}
- Update to version #{new_source.version}
EOS
      @metadata[:changelog_entries] ||= []
      @metadata[:changelog_entries].unshift changelog_entry.rstrip
    end

    public

    # Return properly formatted rpmspec as string
    # 
    # @return [String] string representation of rpm spec
    def to_string
      contents = @metadata[:contents]

      # replace version / release
      contents.gsub!(SPEC_VERSION_MATCHER, "Version: #{@metadata[:version]}")
      contents.gsub!(SPEC_RELEASE_MATCHER, "Release: #{@metadata[:release]}")

      # add changelog entry
      cp  = contents.index SPEC_CHANGELOG_MATCHER
      cpn = contents.index "\n", cp
      contents = contents[0...cpn+1] +
                 @metadata[:changelog_entries].join("\n\n")

      # update requires/build requires
      rp   = contents.index SPEC_REQUIRES_MATCHER
      brp  = contents.index SPEC_BUILD_REQUIRES_MATCHER
      tp   = rp < brp ? rp : brp

      pp   = contents.index SPEC_SUBPACKAGE_MATCHER
      pp   = -1 if pp.nil?

      lrp  = contents.rindex SPEC_REQUIRES_MATCHER, pp
      lbrp = contents.rindex SPEC_BUILD_REQUIRES_MATCHER, pp
      ltp  = lrp > lbrp ? lrp : lbrp

      ltpn = contents.index "\n", ltp

      contents.slice!(tp...ltpn)
      contents.insert tp,
        (@metadata[:requires].collect { |r| "Requires: #{r}" } +
         @metadata[:build_requires].collect { |r| "BuildRequires: #{r}" }).join("\n")

      # add new files
       fp = contents.index SPEC_FILES_MATCHER
      lfp = contents.index SPEC_SUBPKG_FILES_MATCHER, fp + 1
      lfp = contents.index SPEC_CHANGELOG_MATCHER if lfp.nil?

      contents.insert lfp - 1, @metadata[:new_files].join("\n") + "\n"

      # return new contents
      contents
    end

    def compare(upstream_source)
      same = {}
      diff = {}
      upstream_source.deps.each do |d|
        spec_req =
          @metadata[:requires].find { |r|
            r.split.first == "rubygem(#{d.name})"
          }
        spec_version = !spec_req.nil? ? spec_req.split[1..-1] : nil

        # FIXME interim hack discarding requirement specifier and just
        # comparing value. Should retrieve latest (or min? or both?)
        # dependency which satisfies req and verify it is satisfied by both
        # gem and rpmspec
        upstream_version = d.requirement.to_s.split.last

        same_version = !spec_version.nil? ?
                       (spec_version.last == upstream_version ) : false

        if spec_req.nil?
          diff[d.name] = {:spec => nil, :upstream => d.requirement}
        elsif !same_version
          diff[d.name] = {:spec => spec_version, :upstream => d.requirement}
        else
          same[d.name] = {:spec => spec_version, :upstream => d.requirement}
        end
      end

      @metadata[:requires].each do |req|
        req_name = req.split.first
        # XXX skip already processed gems (due to same FIXME as above)
        processed = !same.keys.find { |k| k == req_name }.nil?
        next unless req =~ /rubygem\(([^\)]*)\).*/ && !processed

        gem_name = $1
        spec_version = req.split[1..-1]

        upstream_dep = upstream_source.deps.find { |d| d.name == gem_name }

        # same FIXME as above
        upstream_version = !upstream_dep.nil? ? 
                           upstream_dep.requirement.to_s.split.last : nil

        same_version = spec_version.last == upstream_version

        if upstream_dep.nil?
          diff[req_name] = {:spec => spec_version, :upstream => nil}
        elsif !same_version
          diff[req_name] = {:spec => spec_version, :upstream => upstream_dep.requirement }
        else
          same[req_name] = {:spec => spec_version, :upstream => upstream_dep.requirement }
        end
      end

      {:same => same, :diff => diff}
    end

  end # class RPMSpec
end # module Polisher
