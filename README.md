# Polisher

[![Gem Version](https://badge.fury.io/rb/polisher.png)](http://badge.fury.io/rb/polisher)
[![Build Status](https://travis-ci.org/ManageIQ/polisher.png)](https://travis-ci.org/ManageIQ/polisher)
[![Code Climate](https://codeclimate.com/github/ManageIQ/polisher.png)](https://codeclimate.com/github/ManageIQ/polisher)
[![Coverage Status](https://coveralls.io/repos/ManageIQ/polisher/badge.png?branch=master)](https://coveralls.io/r/ManageIQ/polisher)
[![Dependency Status](https://gemnasium.com/ManageIQ/polisher.png)](https://gemnasium.com/ManageIQ/polisher)

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
    
    # For Fedora 21 and below also enterprise linux replace dnf with yum
    # install the ruby & curl headers & development tools...
    dnf install ruby-devel libcurl-devel
    dnf group install "Development Tools"

    # ... or install the gem manually
    dnf install rubygem-curb

Replace the 'yum install' commands with the corresponding ones on alternate platforms.

Various polisher subcomponents depend on various command line utilities, these include:

* /usr/bin/git - to checkout git repos
* /usr/bin/koji - to query and build against koji
* /usr/bin/yum - to query yum
* /usr/bin/md5sum - to generate required metadata
* /usr/bin/fedpkg - to query fedora

Some of these are pre-installed on many platforms and some are available via a quick
'dnf install' / 'apt-get' or other. Not all are required for all utilities, see the
specific executables and modules for details.

## Installation

To install the latest release and all ruby dependencies simply run:

    gem install polisher

See the bin/ directory for all executables available, pass '-h' to any to
see specific command line options. To run any command from a local git checkout
of polisher, run the following beforehand:

    export RUBYLIB='lib'

## Documentation and Spec Suite

Polisher comes with complete documentation and a full test suite.

Documentation relies on the 'yard' gem / documentation system, to
generate run:

    rake yard

The test suite is based on rspec, to run:

    rake spec

## Legal & Other

Polisher is Licensed under the [MIT License](https://opensource.org/licenses/MIT), Copyright (C) 2013-2016 Red Hat, Inc.

See the commit log for authors of the project. All feedback and contributions
are more than welcome.

## Authors / Committers

- Mo Morsi
- Jason Frey
- Joe Rafaniello
- Ken Dreyer
- Achilleas Pipinellis
- Oleg Barenboim
- Dominic Cleal
- Josef Stribny
- Sourav Moitra
