# An example generating a patchset from a diff of two gems

require 'polisher/rpm/patch'
require 'polisher/gem'

rails = Polisher::Gem.from_rubygems 'fog', '1.19.0'
other = Polisher::Git::Repo.new :url => 'https://github.com/ManageIQ/fog.git'
other.clone unless other.cloned?

puts rails.diff(other)
