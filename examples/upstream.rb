# A few examples of querying upstream targets of ruby projects

require 'polisher/upstream'

include Polisher

puts Upstream.parse("spec/data/Gemfile")               # => #<Polisher::Gemfile>
puts Upstream.parse("spec/data/rspec-2.12.0.gem")      # => #<Polisher::Gem>
puts Upstream.parse("spec/data/mysql-2.9.1.gemspec")   # => #<Polisher::Gem>

puts Polisher::Gem.local_versions_for('rails')         # => [3.2.13] (corresponding to locally installed versions)
