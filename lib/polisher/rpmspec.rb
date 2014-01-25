# Polisher RPM Spec Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'gem2rpm'
require 'versionomy'
require 'active_support/core_ext'

require 'polisher/core'
require 'polisher/gem'

module Polisher
  class RPMSpec
    class Requirement
      # Bool indiciating if req is a BR
      attr_accessor :br

      # Name of requirement
      attr_accessor :name

      # Condition, eg >=, =, etc
      attr_accessor :condition

      # Version number
      attr_accessor :version

      # Requirement string
      def str
        sp = self.specifier
        sp.nil? ? "#{@name}" : "#{@name} #{sp}"
      end

      # Specified string
      def specifier
        @version.nil? ? nil : "#{@condition} #{@version}"
      end

      def self.parse(str, opts={})
        stra   = str.split
        br = str.include?('BuildRequires')
        name = condition = version = nil

        if str.include?('Requires')
          name      = stra[1] 
          condition = stra[2]
          version   = stra[3]

        else
          name      = stra[0]
          condition = stra[1]
          version   = stra[2]

        end

        req = self.new({:name      => name,
                        :condition => condition,
                        :version   => version,
                        :br        => br}.merge(opts))
        req
      end

      def initialize(args={})
        @br        = args[:br] || false
        @name      = args[:name]
        @condition = args[:condition]
        @version   = args[:version]

        @name.strip!      unless @name.nil?
        @condition.strip! unless @condition.nil?
        @version.strip!   unless @version.nil?
      end

      def ==(other)
        @br        == other.br &&
        @name      == other.name &&
        @condition == other.condition &&
        @version   == other.version
      end

      # Greatest Common Denominator,
      # Max version in list that is less than the local version
      def gcd(versions)
        lversion = Versionomy.parse(self.version)
        versions.collect { |v| Versionomy.parse(v) }.
                 sort { |a,b| a <=> b }.reverse.
                 find { |v| v < lversion }.to_s
      end

      # Minimum gem version which satisfies this dependency
      def min_satisfying_version
        return "0.0"        if self.version.nil?      ||
                               self.condition == '<'  ||
                               self.condition == '<='
        return self.version if self.condition == '='  ||
                               self.condition == '>='
        Versionomy.parse(self.version).bump(:tiny).to_s # self.condition == '>'
      end

      # Max gem version which satisfies this dependency
      #
      # Can't automatically deduce in '<' case, so if that is the conditional
      # we require a version list, and will return the gcd from it
      def max_satisfying_version(versions=nil)
        return Float::INFINITY if self.version.nil?      ||
                                  self.condition == '>'  ||
                                  self.condition == '>='
        return self.version    if self.condition == '='  ||
                                  self.condition == '<='

        raise ArgumentError    if versions.nil?
        self.gcd(versions)
      end

      # Minimum gem version for which this dependency fails
      def min_failing_version
        raise ArgumentError if self.version.nil?
        return "0.0"        if self.condition == '>'  ||
                               self.condition == '>='
        return self.version if self.condition == '<'
        Versionomy.parse(self.version).bump(:tiny).to_s # self.condition == '<=' and '='
      end

      # Max gem version for which this dependency fails
      #
      # Can't automatically deduce in '>=', and '=' cases, so if that is the
      # conditional we require a version list, and will return the gcd from it
      def max_failing_version(versions=nil)
        raise ArgumentError if self.version.nil?      ||
                               self.condition == '<=' ||
                               self.condition == '<'
        return self.version if self.condition == '>'

        raise ArgumentError if versions.nil?
        self.gcd(versions)
      end

      def matches?(gem_dep)
        # FIXME interim hack discarding requirement condition and just
        # comparing value. Should retrieve latest (or min? or both?)
        # dependency which satisfies req and verify it is satisfied by both
        # gem and rpmspec
        upstream_version = gem_dep.requirement.to_s.split.last

        !self.version.nil? && self.version == upstream_version
      end

      def gem?
        !!(self.str =~ SPEC_GEM_REQ_MATCHER)
      end

      def gem_name
        # XXX need to explicitly run regex here to get $1
        !!(self.str =~ SPEC_GEM_REQ_MATCHER) ? $1 : nil
      end
    end

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
       /^%defattr.*/, /^%exclude\s/, /^%{gem_instdir}\/+/]
    
    FILE_MACRO_REPLACEMENTS =
      {"%{_bindir}"    => 'bin',
       "%{gem_libdir}" => 'lib'}

    attr_accessor :metadata

    # Return the currently configured author
    def self.current_author
      ENV['POLISHER_AUTHOR'] || AUTHOR
    end

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

    def requirement_for_gem(gem_name)
      @metadata[:requires] &&
      @metadata[:requires].find { |r| r.gem_name == gem_name }
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
          meta[:requires] << RPMSpec::Requirement.parse($1.strip)
    
        elsif l =~ SPEC_BUILD_REQUIRES_MATCHER &&
              !in_subpackage
          meta[:build_requires] ||= []
          meta[:build_requires] << RPMSpec::Requirement.parse($1.strip)
    
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
        if !r.gem?
          non_gem_requires << r
        elsif !new_source.deps.any? { |d| d.name == r.gem_name }
          extra_gem_requires << r
        #else
        #  spec_version = $2
        end
      }

      @metadata[:build_requires] ||= []
      @metadata[:build_requires].each { |r|
        if !r.gem?
          non_gem_brequires << r
        elsif !new_source.deps.any? { |d| d.name == r.gem_name }
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
              RPMSpec::Requirement.new :name      => "rubygem(#{r.name})",
                                       :condition => e.first.to_s,
                                       :version   => e.last.to_s,
                                       :br        => false
            }
          }
        }.flatten

      @metadata[:build_requires] =
        non_gem_brequires + extra_gem_brequires +
        new_source.dev_deps.collect { |r|
          r.requirement.to_s.split(',').collect { |req|
            expanded = Gem2Rpm::Helpers.expand_requirement [req.split]
            expanded.collect { |e|
              RPMSpec::Requirement.new :name      => "rubygem(#{r.name})",
                                       :condition => e.first.to_s,
                                       :version   => e.last.to_s,
                                       :br        => true
            }
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
          to_add << gem_file.rpmize if !has_file &&
                                       !Gem.ignorable_file?(gem_file)
        }
      }

      @metadata[:new_files] = to_add
    end

    def update_metadata_from(new_source)
      # update to new version
      @metadata[:version] = new_source.version
      @metadata[:release] = "1%{?dist}"

      # add changelog entry
      changelog_entry = <<EOS
* #{Time.now.strftime("%a %b %d %Y")} #{RPMSpec.current_author} - #{@metadata[:version]}-1
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
        (@metadata[:requires].collect { |r| "Requires: #{r.str}" } +
         @metadata[:build_requires].collect { |r| "BuildRequires: #{r.str}" }).join("\n")

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
        spec_req = self.requirement_for_gem(d.name)

        if spec_req.nil?
          diff[d.name] = {:spec     => nil,
                          :upstream => d.requirement.to_s}

        elsif !spec_req.matches?(d)
          diff[d.name] = {:spec     => spec_req.specifier,
                          :upstream => d.requirement.to_s}

        else
          same[d.name] = {:spec     => spec_req.specifier,
                          :upstream => d.requirement.to_s}
        end
      end

      @metadata[:requires].each do |req|
        # XXX skip already processed gems
        # (due to FIXME in Requirement#matches? above)
        processed = !same.keys.find { |k| k == req.name }.nil?
        next unless req.gem? && !processed

        upstream_dep = upstream_source.deps.find { |d| d.name == req.gem_name }

        if upstream_dep.nil?
          diff[req.gem_name] = {:spec     => req.specifier,
                                :upstream => nil}

        elsif !req.matches?(upstream_dep)
          diff[req.gem_name] = {:spec     => req.specifier,
                                :upstream => upstream_dep.requirement.to_s }

        else
          same[req.gem_name] = {:spec     => req.specifier,
                                :upstream => upstream_dep.requirement.to_s }
        end
      end unless @metadata[:requires].nil?

      {:same => same, :diff => diff}
    end

  end # class RPMSpec
end # module Polisher
