%global gem_name activesupport

Summary: Support and utility classes used by the Rails framework
Name: rubygem-%{gem_name}
Epoch: 1
Version: 4.0.0
Release: 1%{?dist}
Group: Development/Languages
License: MIT
URL: http://www.rubyonrails.org

Source0: http://rubygems.org/downloads/activesupport-%{version}.gem

# Also the activesupport gem doesn't ship with the test suite like the other
# Rails rpms, you may check it out like so
# git clone http://github.com/rails/rails.git
# cd rails/activesupport/
# git checkout v4.0.0
# tar czvf activesupport-4.0.0-tests.tgz test/
Source2: activesupport-%{version}-tests.tgz

# Removes code which breaks the test suite due to a
# dependency on a file in the greater rails proj
Patch1: activesupport-tests-fix.patch

# We need to add the bigdecimal dependency to gemspec, otherwise it won't be
# loaded. The reason for this is unbundling it from ruby libdir and moving
# it under %%{gem_dir} (therefore if not in Gemfile, it won't be found).
Patch4: activesupport-add-bigdecimal-dependency.patch

BuildRequires: rubygems-devel
BuildRequires: rubygem(bigdecimal)
BuildRequires: rubygem(builder)
BuildRequires: rubygem(dalli)
BuildRequires: rubygem(i18n) >= 0.6
BuildRequires: rubygem(i18n) < 1.0
BuildRequires: rubygem(minitest)
BuildRequires: rubygem(mocha)
BuildRequires: rubygem(multi_json) >= 1.0
BuildRequires: rubygem(multi_json) < 2
BuildRequires: rubygem(rack)
BuildRequires: rubygem(thread_safe)
BuildRequires: rubygem(tzinfo) >= 0.3.37
BuildRequires: rubygem(tzinfo) < 0.4.0
BuildArch: noarch
Provides: rubygem(%{gem_name}) = %{version}

%description
Utility library which carries commonly used classes and
goodies from the Rails framework

%package doc
Requires: rubygem(foo)
BuildRequires: rubygem(bar)

%description
Documentation for activesupport.

%prep
%setup -q -c -T
%gem_install -n %{SOURCE0}

# move the tests into place
tar xzvf %{SOURCE2} -C .%{gem_instdir}


pushd .%{gem_instdir}
%patch1 -p0
popd

pushd .%{gem_dir}
#%%patch4 -p1
popd

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* %{buildroot}%{gem_dir}

%check
pushd %{buildroot}%{gem_instdir}

ruby -Ilib:test -e "Dir.glob('./test/**/*_test.rb').each {|t| require t}"
popd

%files
%dir %{gem_instdir}
%doc %{gem_instdir}/CHANGELOG.md
%{gem_libdir}
%doc %{gem_instdir}/MIT-LICENSE
%doc %{gem_instdir}/README.rdoc
%{gem_cache}
%{gem_spec}

%files doc
%doc %{gem_docdir}
%{gem_instdir}/test


%changelog
* Fri Aug 09 2013 Josef Stribny <jstribny@redhat.com> - 1:4.0.0-2
- Fix: add minitest to requires

* Tue Jul 30 2013 Josef Stribny <jstribny@redhat.com> - 1:4.0.0-1
- Update to ActiveSupport 4.0.0.

* Tue Mar 19 2013 Vít Ondruch <vondruch@redhat.com> - 1:3.2.13-1
- Update to ActiveSupport 3.2.13.

* Fri Mar 01 2013 Vít Ondruch <vondruch@redhat.com> - 1:3.2.12-2
- Rebuild for https://fedoraproject.org/wiki/Features/Ruby_2.0.0

* Tue Feb 12 2013 Vít Ondruch <vondruch@redhat.com> - 1:3.2.12-1
- Update to ActiveSupport 3.2.12.

* Wed Jan 09 2013 Vít Ondruch <vondruch@redhat.com> - 1:3.2.11-1
- Update to ActiveSupport 3.2.11.

* Thu Jan 03 2013 Vít Ondruch <vondruch@redhat.com> - 1:3.2.10-1
- Update to ActiveSupport 3.2.10.

* Mon Aug 13 2012 Vít Ondruch <vondruch@redhat.com> - 1:3.2.8-1
- Update to ActiveSupport 3.2.8.

* Mon Jul 30 2012 Vít Ondruch <vondruch@redhat.com> - 1:3.2.7-1
- Update to ActiveSupport 3.2.7.

* Wed Jul 18 2012 Bohuslav Kabrda <bkabrda@redhat.com> - 1:3.2.6-1
- Update to ActiveSupport 3.2.6.
- Removed unneeded BuildRoot tag.
- Tests no longer fail with newer versions of Mocha, remove workaround.

* Fri Jun 15 2012 Vít Ondruch <vondruch@redhat.com> - 1:3.0.15-1
- Update to ActiveSupport 3.0.15.

* Fri Jun 01 2012 Vít Ondruch <vondruch@redhat.com> - 1:3.0.13-1
- Update to ActiveSupport 3.0.13.

* Wed Apr 18 2012 Bohuslav Kabrda <bkabrda@redhat.com> - 1:3.0.11-5
- Add the bigdecimal dependency to gemspec.

* Fri Mar 16 2012 Bohuslav Kabrda <bkabrda@redhat.com> - 1:3.0.11-4
- The CVE patch name now contains the CVE id.

* Mon Mar 05 2012 Bohuslav Kabrda <bkabrda@redhat.com> - 1:3.0.11-3
- Patch for CVE-2012-1098

* Tue Jan 24 2012 Bohuslav Kabrda <bkabrda@redhat.com> - 1:3.0.11-1
- Rebuilt for Ruby 1.9.3.
- Update to ActiveSupport 3.0.11.

* Mon Aug 22 2011 Vít Ondruch <vondruch@redhat.com> - 1:3.0.10-1
- Update to ActiveSupport 3.0.10

* Fri Jul 01 2011 Vít Ondruch <vondruch@redhat.com> - 1:3.0.9-1
- Update to ActiveSupport 3.0.9
- Changed %%define into %%global
- Removed unnecessary %%clean section

* Thu Jun 16 2011 Mo Morsi <mmorsi@redhat.com> - 1:3.0.5-3
- Reverting accidental change adding a few gem flags

* Thu Jun 16 2011 Mo Morsi <mmorsi@redhat.com> - 1:3.0.5-2
- Include fix for CVE-2011-2197

* Thu Mar 24 2011 Vít Ondruch <vondruch@redhat.com> - 1:3.0.5-1
- Update to ActiveSupport 3.0.5
- Remove Rake dependnecy

* Mon Feb 14 2011 Mohammed Morsi <mmorsi@redhat.com> - 1:3.0.3-4
- fix bad dates in the spec changelog

* Thu Feb 10 2011 Mohammed Morsi <mmorsi@redhat.com> - 1:3.0.3-3
- include i18n runtime dependency

* Wed Feb 09 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1:3.0.3-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Mon Jan 10 2011 Mohammed Morsi <mmorsi@redhat.com> - 1:3.0.3-1
- update to rails 3

* Wed Aug 25 2010 Mohammed Morsi <mmorsi@redhat.com> - 1:2.3.8-2
- bumped version

* Wed Aug 04 2010 Mohammed Morsi <mmorsi@redhat.com> - 1:2.3.8-1
- Update to 2.3.8
- Added check section with rubygem-mocha dependency
- Added upsteam Rakefile and test suite to run tests

* Thu Jan 28 2010 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 1:2.3.5-1
- Update to 2.3.5

* Wed Oct  7 2009 David Lutterkort <lutter@redhat.com> - 1:2.3.4-2
- Bump Epoch to ensure upgrade path from F-11

* Mon Sep 7 2009 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 2.3.4-1
- Update to 2.3.4 (bug 520843, CVE-2009-3009)

* Sun Jul 26 2009 Jeroen van Meeuwen <j.van.meeuwen@ogd.nl> - 2.3.3-1
- New upstream version

* Mon Mar 16 2009 Jeroen van Meeuwen <kanarip@fedoraproject.org> - 2.3.2-1
- New upstream version

* Wed Feb 25 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.2.2-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_11_Mass_Rebuild

* Mon Nov 24 2008 Jeroen van Meeuwen <kanarip@fedoraproject.org> - 2.2.2-1
- New upstream version

* Tue Sep 16 2008 David Lutterkort <dlutter@redhat.com> - 2.1.1-1
- New version (fixes CVE-2008-4094)

* Thu Jul 31 2008 Michael Stahnke <stahnma@fedoraproject.org> - 2.1.0-1
- New Upstream

* Mon Apr 07 2008 David Lutterkort <dlutter@redhat.com> - 2.0.2-1
- New version

* Mon Dec 10 2007 David Lutterkort <dlutter@redhat.com> - 2.0.1-1
- New version

* Wed Nov 28 2007 David Lutterkort <dlutter@redhat.com> - 1.4.4-3
- Fix buildroot

* Tue Nov 13 2007 David Lutterkort <dlutter@redhat.com> - 1.4.4-2
- Install README and CHANGELOG in _docdir

* Tue Oct 30 2007 David Lutterkort <dlutter@redhat.com> - 1.4.4-1
- Initial package
