gem_dependency_checker
======================
Check gem related dependencies against your platform with ease!

<pre>
 .77                                                                 7.         
  +$                                                                 =~         
+?ZZZII                                                           .Z$$$$$$      
$~~:,.$Z                                                           $~~:,.7      
 ?~:,, .............................................................=~:,,.      
  ~::,..rails.......................................................~~:,.      
  ~~:,, .........rack................json...........................=~:,,      
  =~::,.....................sass............activerecord..............~::,.     
   ~~:,.=....eruby...................................................~~:,.~    
   +~:,,.................haml.........................................?~::,.    
    ~::,. ........................rspec................................~~:,.:   
    =~:,,:.........................................bundler.............~~:,,    
     ~I7I..........rvm.................................................,~7?II   
    $$$$$$$O                                                           $$$$$$$$ 
     .ZO7Z,                                                             .+ZIZ.  
        7                                                                  7    
        $I                                                                 ZI   
</pre>

gem_dependency_checker is a set of small utilities that provides platform specific
mechanisms to lookup and query gem dependencies. Primarily meant to be invoked from
the command line these tools lookup gem, gemspec, and gemfile dependencies against
various resources including yum, koji, git, fedora, and more.

Pass --help to gem_dependency_checker.rb to see complete command line usage.
More information on each utility can be found in the header contents. The
[http://ascii.io/a/4488](following) [http://ascii.io/a/4489](asciicasts)
demonstrate the utilities in action.
