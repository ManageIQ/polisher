module Polisher
  module Test
    GEM_SPEC = {
      :path     => "#{data_dir}/mysql-2.9.1.gemspec",
      :name     => 'mysql',
      :version  => '2.9.1',
      :deps     => [],
      :dev_deps => [::Gem::Dependency.new('rdoc', '~> 3.10', :development),
                    ::Gem::Dependency.new('rake-compiler', '~> 0.8.1', :development),
                    ::Gem::Dependency.new('hoe', '~> 3.5', :development)]
    }
  end # module Test
end # module Polisher
