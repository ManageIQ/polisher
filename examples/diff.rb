# An example generating a patchset from a diff of two gems

require 'colored'
require 'polisher/rpm/patch'
require 'polisher/gem'

fog = Polisher::Gem.from_rubygems 'fog', '1.19.0'
other = Polisher::Git::Repo.new :url => 'https://github.com/ManageIQ/fog.git'
other.clone unless other.cloned?

diff = fog.diff(other)

patches = Polisher::RPM::Patch.from diff
puts patches.collect { |p| p.title.blue.bold + ":\r\n " + p.content[1..50] + '...'.blue.bold }
