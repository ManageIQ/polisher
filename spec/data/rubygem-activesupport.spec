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

Requires: ruby(rubygems)
Requires: ruby(release)
# Let's keep Requires and BuildRequires sorted alphabeticaly
Requires: rubygem(bigdecimal)
Requires: rubygem(dalli)
Requires: rubygem(i18n) >= 0.6
Requires: rubygem(i18n) < 1.0
Requires: rubygem(minitest) >= 4.2
Requires: rubygem(minitest) < 5
Requires: rubygem(multi_json) >= 1.0
Requires: rubygem(multi_json) < 2
Requires: rubygem(rack)
Requires: rubygem(thread_safe)
Requires: rubygem(tzinfo) >= 0.3.37
Requires: rubygem(tzinfo) < 0.4.0
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
%doc %{gem_docdir}
%{gem_cache}
%{gem_spec}
%{gem_instdir}/test


%changelog
* Fri Aug 09 2013 Josef Stribny <jstribny@redhat.com> - 1:4.0.0-2
- Fix: add minitest to requires

* Tue Jul 30 2013 Josef Stribny <jstribny@redhat.com> - 1:4.0.0-1
- Update to ActiveSupport 4.0.0.

* Tue Mar 19 2013 Vit Ondruch <vondruch@redhat.com> - 1:3.2.13-1
- Update to ActiveSupport 3.2.13.
