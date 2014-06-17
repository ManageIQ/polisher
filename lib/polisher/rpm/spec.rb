# Polisher RPM Spec Represenation
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/core'
require 'polisher/gem'
require 'polisher/rpm/requirement'
require 'polisher/component'

module Polisher
  deps = ['gem2rpm', 'versionomy', 'active_support', 'active_support/core_ext']
  Component.verify("RPM::Spec", *deps) do
    module RPM
      class Spec
        # RPM Spec Requirement Prefix
        def self.requirement_prefix
          Requirement.prefix
        end

        def requirement_prefix
          self.class.requirement_prefix
        end

        def self.package_prefix
          requirement_prefix
        end

        AUTHOR = "#{ENV['USER']} <#{ENV['USER']}@localhost.localdomain>"

        COMMENT_MATCHER             = /^\s*#.*/
        GEM_NAME_MATCHER            = /^%global\s*gem_name\s(.*)$/
        SPEC_NAME_MATCHER           = /^Name:\s*#{package_prefix}-(.*)$/
        SPEC_VERSION_MATCHER        = /^Version:\s*(.*)$/
        SPEC_RELEASE_MATCHER        = /^Release:\s*(.*)$/
        SPEC_REQUIRES_MATCHER       = /^Requires:\s*(.*)$/
        SPEC_BUILD_REQUIRES_MATCHER = /^BuildRequires:\s*(.*)$/
        SPEC_GEM_REQ_MATCHER        = /^.*\s*#{requirement_prefix}\((.*)\)(\s*(.*))?$/
        SPEC_SUBPACKAGE_MATCHER     = /^%package\s(.*)$/
        SPEC_CHANGELOG_MATCHER      = /^%changelog$/
        SPEC_FILES_MATCHER          = /^%files$/
        SPEC_SUBPKG_FILES_MATCHER   = /^%files\s*(.*)$/
        SPEC_EXCLUDED_FILE_MATCHER  = /^%exclude\s+(.*)$/
        SPEC_CHECK_MATCHER          = /^%check$/

        FILE_MACRO_MATCHERS         =
          [/^%doc\s/,     /^%config\s/,  /^%attr\s/,
           /^%verify\s/,  /^%docdir.*/,  /^%dir\s/, /^%defattr.*/,
           /^%{gem_instdir}\/+/, /^%{gem_cache}/, /^%{gem_spec}/, /^%{gem_docdir}/]

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

        # Return list of all files in the spec
        def files
          pkg_files.values.flatten
        end

        # Return subpkg containing the specified file
        def subpkg_containing(file)
          pkg_files.each do |pkg, spec_files|
            return pkg if spec_files.include?(file)
          end
          nil
        end

        # Return gem corresponding to spec name/version
        def upstream_gem
          @gem, @update_gem = nil, false if @update_gem
          @gem ||= Polisher::Gem.from_rubygems gem_name, version
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
              tereq = Requirement.new :name      => "#{requirement_prefix}(#{gem_dep.name})",
                                      :condition => ereq.first,
                                      :version   => ereq.last.to_s
              reqs.any? { |req| req.matches?(tereq)}
            }
          }
        end

        # Return list of gem dependencies for which we have no
        # corresponding requirements
        def missing_deps_for(gem)
          # Comparison by name here assuming if it is in existing spec,
          # spec author will have ensured versions are correct for their purposes
          gem.deps.select { |dep| requirements_for_gem(dep.name).empty? }
        end
  
        # Return list of gem dev dependencies for which we have
        # no corresponding requirements
        def missing_dev_deps_for(gem)
          # Same note as in #missing_deps_for above
          gem.dev_deps.select { |dep| build_requirements_for_gem(dep.name).empty? }
        end
  
        # Return list of dependencies of upstream gem which
        # have not been included
        def excluded_deps
          missing_deps_for(upstream_gem)
        end
  
        # Return boolean indicating if the specified gem is on excluded list
        def excludes_dep?(gem_name)
          excluded_deps.any? { |d| d.name == gem_name }
        end
  
        # Return list of dev dependencies of upstream gem which
        # have not been included
        def excluded_dev_deps
          missing_dev_deps_for(upstream_gem)
        end
  
        # Return boolean indicating if the specified gem is on
        # excluded dev dep list
        def excludes_dev_dep?(gem_name)
          excluded_dev_deps.any? { |d| d.name == gem_name }
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

        # Helper to return bool indicating if specified gem file is satisfied
        # by specified spec file.
        #
        # Spec file satisfies gem file if they are the same or the spec file
        # corresponds to the the directory in which the gem file resides.
        def self.file_satisfies?(spec_file, gem_file)
          # If spec file for which gemfile.gsub(/^specfile/)
          # is different than the gemfile the spec contains the gemfile
          #
          # TODO: need to incorporate regex matching into this
          gem_file.gsub(/^#{spec_file.unrpmize}/, '') != gem_file
        end

        # Return bool indicating if spec is missing specified gemfile.
        def missing_gem_file?(gem_file)
          files.none? { |spec_file| self.class.file_satisfies?(spec_file, gem_file) }
        end

        # Return list of gem files for which we have no corresponding spec files
        def missing_files_for(gem)
          # we check for files in the gem for which there are no spec files
          # corresponding to gem file or directory which it resides in
          gem.file_paths.select { |gem_file| missing_gem_file?(gem_file) }
        end

        # Return list of files in upstream gem which have not been included
        def excluded_files
          # TODO: also append files marked as %{exclude} (or handle elsewhere?)
          missing_files_for(upstream_gem)
        end

        # Return boolean indicating if the specified file is on excluded list
        def excludes_file?(file)
          excluded_files.include?(file)
        end

        # Return extra package file _not_ in the specified gem
        def extra_gem_files(gem = nil)
          gem ||= upstream_gem
          pkg_extra = {}
          pkg_files.each do |pkg, files|
            extra = files.select { |spec_file| !gem.has_file_satisfied_by?(spec_file) }
            pkg_extra[pkg] = extra unless extra.empty?
          end
          pkg_extra
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

              if l =~ SPEC_EXCLUDED_FILE_MATCHER
                sl = Regexp.last_match(1)
                meta[:pkg_excludes] ||= {}
                meta[:pkg_excludes][tgt] ||= []
                meta[:pkg_excludes][tgt] << sl unless sl.blank?

              else
                sl = l.strip
                meta[:pkg_files] ||= {}
                meta[:pkg_files][tgt] ||= []
                meta[:pkg_files][tgt] << sl unless sl.blank?
              end
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
          update_contents
        end

        private

        # Update spec dependencies from new source
        def update_deps_from(new_source)
          @metadata[:requires] =
            non_gem_requirements +
            extra_gem_requirements(new_source) +
            new_source.deps.select { |r| !excludes_dep?(r.name) }
                      .collect { |r| RPM::Requirement.from_gem_dep(r) }.flatten

          @metadata[:build_requires] =
            non_gem_build_requirements +
            extra_gem_build_requirements(new_source) +
            new_source.dev_deps.select { |r| !excludes_dev_dep?(r.name) }
                      .collect { |r| RPM::Requirement.from_gem_dep(r, true) }.flatten
        end

        # Internal helper to update spec files from new source
        def update_files_from(new_source)
          # populate file list from rpmized versions of new source files
          # minus excluded files minus duplicates (files taken care by other
          # dirs on list)
          #
          # TODO: also detect / add files from SOURCES & PATCHES
          gem_files = new_source.file_paths - excluded_files
          gem_files.reject! do |file|
            gem_files.any? do |other|
              other != file && self.class.file_satisfies?(other, file)
            end
          end

          @metadata[:new_files] = {}
          @metadata[:pkg_excludes] ||= {}
          gem_files.each do |gem_file|
            pkg = subpkg_containing(gem_file)
            pkg = gem_name if pkg.nil?
            if Gem.ignorable_file?(gem_file)
              @metadata[:pkg_excludes] ||= []
              @metadata[:pkg_excludes][pkg] << gem_file.rpmize

            elsif Gem.doc_file?(gem_file)
              @metadata[:new_files]['doc'] ||= []
              @metadata[:new_files]['doc'] << gem_file.rpmize

            else
              @metadata[:new_files][pkg] ||= []
              @metadata[:new_files][pkg] << gem_file.rpmize
            end
          end

          extra_gem_files.each do |pkg, files|
            @metadata[:new_files][pkg] ||= []
            @metadata[:new_files][pkg]  += files.collect { |file| file.rpmize }
          end
        end

        # Internal helper to update spec metadata from new source
        def update_metadata_from(new_source)
          # update to new version
          @metadata[:version] = new_source.version
          @metadata[:release] = "1%{?dist}"

          # invalidate the local gem
          @update_gem = true

          # add changelog entry
          changelog_entry = <<EOS
* #{Time.now.strftime("%a %b %d %Y")} #{RPM::Spec.current_author} - #{@metadata[:version]}-1
- Update to version #{new_source.version}
EOS
          @metadata[:changelog_entries] ||= []
          @metadata[:changelog_entries].unshift changelog_entry.rstrip
        end

        def update_metadata_contents
          # replace version / release
          @metadata[:contents].gsub!(SPEC_VERSION_MATCHER,
                                     "Version: #{@metadata[:version]}")
          @metadata[:contents].gsub!(SPEC_RELEASE_MATCHER,
                                     "Release: #{@metadata[:release]}")
        end

        def update_changelog
          # add changelog entry
          cp  = @metadata[:contents].index SPEC_CHANGELOG_MATCHER
          cpn = cp.nil? ? (@metadata[:contents].length - 1) :
                          (@metadata[:contents].index "\n", cp) + 1
          @metadata[:contents] = @metadata[:contents][0...cpn] +
                                 @metadata[:changelog_entries].join("\n\n")
        end

        def requires_contents
          @metadata[:requires].collect { |r| "Requires: #{r.str}" }.join("\n")
        end

        def build_requires_contents
          @metadata[:build_requires].collect { |r| "BuildRequires: #{r.str}" }
                                    .join("\n")
        end

        def update_requires
          # update requires/build requires
          rp   = @metadata[:contents].index SPEC_REQUIRES_MATCHER
          brp  = @metadata[:contents].index SPEC_BUILD_REQUIRES_MATCHER
          tp   = rp < brp ? rp : brp

          pp   = @metadata[:contents].index SPEC_SUBPACKAGE_MATCHER
          pp   = -1 if pp.nil?

          lrp  = @metadata[:contents].rindex SPEC_REQUIRES_MATCHER, pp
          lbrp = @metadata[:contents].rindex SPEC_BUILD_REQUIRES_MATCHER, pp
          ltp  = lrp > lbrp ? lrp : lbrp

          ltpn = @metadata[:contents].index "\n", ltp

          @metadata[:contents].slice!(tp...ltpn)
          @metadata[:contents].insert tp, requires_contents + "\n" +
                                          build_requires_contents
        end

        def new_files_contents_for(pkg)
          title = pkg == gem_name ? "%files\n" : "%files #{pkg}\n"
          contents = @metadata[:new_files][pkg].join("\n") + "\n"
          title + contents
        end

        def new_subpkg_files_contents
          @metadata[:new_files].keys
            .select { |pkg| pkg != gem_name }
            .collect { |pkg| new_files_contents_for(pkg) }.join("\n\n") + "\n\n"
        end

        def excludes_contents
          @metadata[:pkg_excludes][gem_name]
            .collect { |exclude| "%exclude #{exclude}" }
            .join("\n") + "\n\n"
        end

        def update_files
          # update files
          fp = @metadata[:contents].index SPEC_FILES_MATCHER
          lfp = @metadata[:contents].index SPEC_CHANGELOG_MATCHER
          @metadata[:contents].slice!(fp...lfp)

          contents = new_files_contents_for(gem_name) +
                     excludes_contents +
                     new_subpkg_files_contents

          @metadata[:contents].insert fp, contents
        end

        def update_contents
          update_metadata_contents
          update_changelog
          update_requires
          update_files
        end

        public

        # Return contents of spec as string
        #
        # @return [String] string representation of rpm spec
        def to_string
          @metadata[:contents]
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
  end # Component.verify("RPM::Spec")
end # module Polisher
