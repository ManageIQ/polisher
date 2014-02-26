# An example post-processing workflow using polisher

require 'polisher/git'
require 'polisher/rpm/spec'
require 'polisher/gem'

git  = Polisher::GitPackage.clone('rails')
spec = Polisher::RPM::Spec.parse(File.read('rubygem-rails.spec'))
gem  = Polisher::Gem.retrieve('rails')
spec.update_to gem
puts spec.to_string
