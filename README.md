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

## Installation

Polisher is made available through [rubygems](http://rubygems.org/gems/polisher). To
install the latest release and all dependencies simply run:

    gem install polisher

See the bin/ directory for all executables available, pass '-h' to any to
see specific command line options. A few select utilities are highlighted below

### gem_dependency_checker

A utility to cross reference rubygems and bundler gemfiles against various downstream
resources including the koji build system, distgit (as used by Fedora), and more.

### git_gem_updater

A script that clones a rubygem maintained by distgit and update it to the latest
version of the package available on rubygems (or the specified version if given).

### ruby_rpm_spec_updater

A tool to update a given ruby gem or application based rpm spec to the specified
new source (as specified by a gem, gemspec, or gemfile)

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

Polisher is Licensed under the MIT License, Copyright (C) 2013 Red Hat, Inc.

See the commit log for authors of the project. All feedback and contributions
are more than welcome.
