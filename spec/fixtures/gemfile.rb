module Polisher
  module Test
    GEMFILE = {
      :path     => "#{data_dir}/Gemfile",
      :contents => File.read("#{data_dir}/Gemfile"),
      :deps     => [::Gem::Dependency.new("rubygems", ::Gem::Requirement.new([">= 0"]), :runtime),
                    ::Gem::Dependency.new("cinch", ::Gem::Requirement.new([">= 0"]), :runtime)]
    }
  end # module Test
end # module Polisher
