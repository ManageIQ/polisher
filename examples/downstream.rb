# A few examples of querying downstream targets of ruby projects

require 'polisher/git'
require 'polisher/koji'
require 'polisher/yum'

include Polisher

puts GitPackage.version_for('rails') # => 4.0.2 (corresponding to rawhide)
puts Koji.versions_for('rails')      # => 4.0.1, 4.0.1 (corresponding to stable releases)
puts Yum.version_for('rails')        # => 3.2.13 (corresponding to local yum installed version)
