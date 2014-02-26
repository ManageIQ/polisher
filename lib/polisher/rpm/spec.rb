# Polisher RPM Spec Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'gem2rpm'
require 'versionomy'
require 'active_support/core_ext'

require 'polisher/core'
require 'polisher/gem'
require 'polisher/rpm/requirement'

module Polisher
  module RPM
    class Spec
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
      SPEC_CHECK_MATCHER          = /^%check$/
      
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
  
      # Return boolean indicating if spec has a %check section
      def has_check?
        @metadata.has_key?(:has_check) && @metadata[:has_check]
      end
  
      # Return all the Requires for the specified gem
      def requirements_for_gem(gem_name)
        @metadata[:requires].nil? ? [] :
        @metadata[:requires].select { |r| r.gem_name == gem_name }
      end

      # Return all the BuildRequires for the specified gem
      def build_requirements_for_gem(gem_name)
        @metadata[:build_requires].nil? ? [] :
        @metadata[:build_requires].select { |r| r.gem_name == gem_name }
      end

      # Return bool indicating if this spec specifies all the
      # requirements in the specified gem dependency
      #
      # @param [Gem::Dependency] gem_dep dependency which to retreive / compare
      # requirements
      def has_all_requirements_for?(gem_dep)
        reqs = self.requirements_for_gem gem_dep.name
        # create a spec requirement dependency for each expanded subrequirement,
        # verify we can find a match for that
        gem_dep.requirement.to_s.split(',').all? { |greq|
          Gem2Rpm::Helpers.expand_requirement([greq.split]).all? { |ereq|
            tereq = Requirement.new :name      => "rubygem(#{gem_dep.name})",
                                    :condition => ereq.first,
                                    :version   => ereq.last.to_s
            reqs.any? { |req| req.matches?(tereq)}
          }
        }
      end

      # Return all gem Requires
      def gem_requirements
        @metadata[:requires].nil? ? [] :
        @metadata[:requires].select { |r| r.gem? }
      end

      # Return all gem BuildRequires
      def gem_build_requirements
        @metadata[:build_requires].nil? ? [] :
        @metadata[:build_requires].select { |r| r.gem? }
      end

      # Return all non gem Requires
      def non_gem_requirements
        @metadata[:requires].nil? ? [] :
        @metadata[:requires].select { |r| !r.gem? }
      end

      # Return all non gem BuildRequires
      def non_gem_build_requirements
        @metadata[:build_requires].nil? ? [] :
        @metadata[:build_requires].select { |r| !r.gem? }
      end

      # Return all gem requirements _not_ in the specified gem
      def extra_gem_requirements(gem)
        gem_reqs = gem.deps.collect { |d| requirements_for_gem(d.name) }.flatten
        gem_requirements - gem_reqs
      end

      # Return all gem build requirements _not_ in the specified gem
      def extra_gem_build_requirements(gem)
        gem_reqs = gem.deps.collect { |d| requirements_for_gem(d.name) }.flatten
        gem_build_requirements - gem_reqs
      end
  
      # Parse the specified rpm spec and return new RPM::Spec instance from metadata
      #
      # @param [String] string contents of spec to parse
      # @return [Polisher::RPM::Spec] spec instantiated from rpmspec metadata
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
            meta[:requires] << RPM::Requirement.parse($1.strip)
      
          elsif l =~ SPEC_BUILD_REQUIRES_MATCHER &&
                !in_subpackage
            meta[:build_requires] ||= []
            meta[:build_requires] << RPM::Requirement.parse($1.strip)
      
          elsif l =~ SPEC_CHANGELOG_MATCHER
            in_changelog = true
      
          elsif l =~ SPEC_FILES_MATCHER
            subpkg_name = nil
            in_files = true
      
          elsif l =~ SPEC_SUBPKG_FILES_MATCHER
            subpkg_name = $1.strip
            in_files = true
  
          elsif l =~ SPEC_CHECK_MATCHER
            meta[:has_check] = true
      
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
  
      # Update RPM::Spec metadata to new gem
      #
      # @param [Polisher::Gem] new_source new gem to update rpmspec to
      def update_to(new_source)
        update_deps_from(new_source)
        update_files_from(new_source)
        update_metadata_from(new_source)
      end
  
      private

      # Update spec dependencies from new source
      def update_deps_from(new_source)
        @metadata[:requires] =
          non_gem_requirements +
          extra_gem_requirements(new_source) +
          new_source.deps.collect { |r|
            RPM::Requirement.from_gem_dep(r)
          }.flatten
  
        @metadata[:build_requires] =
          non_gem_build_requirements +
          extra_gem_build_requirements(new_source) +
          new_source.dev_deps.collect { |r|
            RPM::Requirement.from_gem_dep(r, true)
          }.flatten
      end
  
      # Internal helper to update spec files from new source
      def update_files_from(new_source)
        to_add = new_source.file_paths
        @metadata[:files] ||= {}
        @metadata[:files].each { |pkg,spec_files|
          (new_source.file_paths & to_add).each { |gem_file|
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
  
      # Internal helper to update spec metadata from new source
      def update_metadata_from(new_source)
        # update to new version
        @metadata[:version] = new_source.version
        @metadata[:release] = "1%{?dist}"
  
        # add changelog entry
        changelog_entry = <<EOS
* #{Time.now.strftime("%a %b %d %Y")} #{RPM::Spec.current_author} - #{@metadata[:version]}-1
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
  
      # Compare this spec to a sepecified upstream gem source
      # and return result.
      #
      # upstream_source should be an instance of Polisher::Gem,
      # Polisher::Gemfile, or other class defining a 'deps'
      # accessor that returns an array of Gem::Requirement dependencies
      #
      # Result will be a hash containing the shared dependencies as
      # well as those that differ and their respective differences
      def compare(upstream_source)
        same = {}
        diff = {}
        upstream_source.deps.each do |d|
          spec_reqs = self.requirements_for_gem(d.name)
          spec_reqs_specifier = spec_reqs.empty? ? nil :
               spec_reqs.collect { |req| req.specifier }
  
          if spec_reqs.nil?
            diff[d.name] = {:spec     => nil,
                            :upstream => d.requirement.to_s}
  
          elsif !spec_reqs.any? { |req| req.matches?(d) } ||
                !self.has_all_requirements_for?(d)
            diff[d.name] = {:spec     => spec_reqs_specifier,
                            :upstream => d.requirement.to_s}
  
          elsif !diff.has_key?(d.name)
            same[d.name] = {:spec     => spec_reqs_specifier,
                            :upstream => d.requirement.to_s }
          end
        end
  
        @metadata[:requires].each do |req|
          next unless req.gem?
  
          upstream_dep = upstream_source.deps.find { |d| d.name == req.gem_name }
  
          if upstream_dep.nil?
            diff[req.gem_name] = {:spec     => req.specifier,
                                  :upstream => nil}
  
          elsif !req.matches?(upstream_dep)
            diff[req.gem_name] = {:spec     => req.specifier,
                                  :upstream => upstream_dep.requirement.to_s }
  
          elsif !diff.has_key?(req.gem_name)
            same[req.gem_name] = {:spec     => req.specifier,
                                  :upstream => upstream_dep.requirement.to_s }
          end
        end unless @metadata[:requires].nil?
  
        {:same => same, :diff => diff}
      end
  
    end # class Spec
  end # module RPM
end # module Polisher
