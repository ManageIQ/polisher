# A few examples illustrating polisher's core extensions

require 'polisher/core'

puts "rails.gem".gem?           # => true
puts "rails".gem?               # => false

puts "rake.gemspec".gemspec?    # => true
puts "rake".gemspec?            # => false

puts "/foo/Gemfile".gemfile?    # => true
puts "/foo/Gemfile.in".gemfile? # => false

puts "%doc lib/foo.rb".unrpmize # => lib/foo.rb
puts "%{_bindir}/rake".unrpmize # => /bin/rake

puts "/bin/rake".rpmize         # => "%{_bindir}/rake"
