Polisher
======================
Ruby Post-Publishing Processor - Polish your Ruby projects with ease!

<pre>
 .77                                                                 7.         
  +$                                                                 =~         
+?ZZZII                                                           .Z$$$$$$      
$~~:,.$Z                                                           $~~:,.7      
 ?~:,, .......................................redmine...............=~:,,.      
  ~::,..rails.......................................................~~:,.      
  ~~:,, .........rack................json...........................=~:,,      
  =~::,.....................sass............activerecord..............~::,.     
   ~~:,.=....eruby...................................................~~:,.~    
   +~:,,.................haml......................eventmachine.......?~::,.    
    ~::,. ........................rspec................................~~:,.:   
    =~:,,:.........................................bundler.............~~:,,    
     ~I7I..........rvm..................rake...........................,~7?II   
    $$$$$$$O                                                           $$$$$$$$ 
     .ZO7Z,                                                             .+ZIZ.  
        7                                                                  7    
        $I                                                                 ZI   
</pre>

Polisher is a Ruby module and set of utilities aimed to assisting the post-publishing
packaging process for Ruby gems and applications.

Provided are a series of tools geared towards querying rubygems.org and other upstream
ruby sources for metadata as well as downstream sources such as the Fedora and Debian
distributions to cross reference various supported stacks vendored by each.

Polisher also includes utilities to integrate and hook into various build and install workflows
used by both upstream and downstream developers to synergize operations and streamline
the packaging and support process.

## Dependencies

Polisher is made available through [rubygems](http://rubygems.org/gems/polisher).

Polisher dependends on the 'curb' rubygem which in return depends on the curl-devel
headers. The user should install those and the development tools for their platform
or install the curb gem packaged by their distribution like so:

    # install the ruby & curl headers & development tools...
    yum install ruby-devel libcurl-devel
    yum group install "Development Tools"

    # ... or install the gem manually
    yum install rubygem-curb

Replace the 'yum install' commands with the corresponding ones on alternate platforms.

Various polisher subcomponents depend on various command line utilities, these include:

* /usr/bin/git - to checkout git repos
* /usr/bin/koji - to query and build against koji
* /usr/bin/yum - to query yum
* /usr/bin/md5sum - to generate required metadata
* /usr/bin/fedpkg - to query fedora

Some of these are pre-installed on many platforms and some are available via a quick
'yum install' / 'apt-get' or other. Not all are required for all utilities, see the
specific executables and modules for details.

## Installation

To install the latest release and all ruby dependencies simply run:

    gem install polisher

See the bin/ directory for all executables available, pass '-h' to any to
see specific command line options. To run any command from a local git checkout 
of polisher, run the following beforehand:

    export RUBYLIB='lib'

A few select utilities are highlighted below.

### gem_dependency_checker

A utility to cross reference rubygems and bundler gemfiles against various downstream
resources including the koji build system, distgit (as used by Fedora), and more.

For example to check a specified ruby app for compatability in koji and yum:

    gem_dependency_checker.rb --gemfile ~/myapp/Gemfile -k -y

### git_gem_updater

A script that clones a rubygem maintained by distgit and update it to the latest
version of the package available on rubygems (or the specified version if given).
A scratch built will be run and if all goes will a commit staged so that the end
user just has to 'git push' the updated package to the distro.

Simply specify the name of the gem to update like so:

    git_gem_updater.rb -n rails

Alternatively if "-u" is specified with a Fedora username, all the packages the
user owns will be checked out and updated.

## git_gem_diff

A script that does a source comparison between a gem maintained in git against
its corresponding rubygems.org gem.

Simply specify the url to the git repo and the tool will automatically detect
the version of the gem to retrieve and run the diff on

    git_gem_diff.rb -g https://github.com/ManageIQ/polisher.git

### ruby_rpm_spec_updater

A tool to update a given ruby gem or application based rpm spec to the specified
new source (as specified by a gem, gemspec, or gemfile).

Simply pass it the location of the spec to update, and optionally a upstream
source which to update from and the utility will print out the updated spec
to STDOUT.

    ruby_rpm_spec_updater.rb ~/rpmbuild/SPECS/rubygem-rails.spec rails-5.0.0.gem

### check_ruby_spec

A tool to compare the given ruby based rpm spec against the specified source
and/or the corresponding gem retrieved from rubygems.org

    check_ruby_spec.rb ~/rpmbuild/SPECS/rubygem-polisher.spec

This will retrieve the gem and check the spec for consistency, reporting
any discrepancies.

### polisher

The core library behind these utilities, polisher provides reusable modules to
query and interface with upstream ruby sources and downstream vendors and systems.

## Documentation and Spec Suite

Polisher comes with complete documentation and a full test suite.

Documentation relies on the 'yard' gem / documentation system, to
generate run:

    rake yard

The test suite is based on rspec, to run:

    rake spec

## Legal & Other

Polisher is Licensed under the MIT License, Copyright (C) 2013-2014 Red Hat, Inc.

See the commit log for authors of the project. All feedback and contributions
are more than welcome.
