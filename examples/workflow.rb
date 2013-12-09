# An example post-processing workflow using polisher

require 'polisher/git'
require 'polisher/rpmspec'
require 'polisher/gem'

git  = Polisher::GitPackage.clone('rails')
spec = Polisher::RPMSpec.parse(File.read('rubygem-rails.spec'))
gem  = Polisher::Gem.retrieve('rails')
spec.update_to gem
puts spec.to_string
