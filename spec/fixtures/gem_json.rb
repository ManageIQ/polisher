module Polisher
  module Test
    module Fixtures
      class GemJson
        def url
          @url ||="https://rubygems.org/api/v1/gems/rails.json"
        end

        def json_path
          @json_path ||= "#{data_dir}/rails.json"
        end

        def json
          @json ||= File.read(json_path)
        end

        def name
          @name ||= 'rails'
        end

        def version
          @version ||= '4.0.1'
        end

        def deps
          @deps ||= [::Gem::Dependency.new("actionmailer", '= 4.0.1'),
                     ::Gem::Dependency.new("actionpack", '= 4.0.1'),
                     ::Gem::Dependency.new("activerecord", '= 4.0.1'),
                     ::Gem::Dependency.new("activesupport", '= 4.0.1'),
                     ::Gem::Dependency.new("bundler", "< 2.0", ">= 1.3.0"),
                     ::Gem::Dependency.new("railties", '= 4.0.1'),
                     ::Gem::Dependency.new("sprockets-rails", '~> 2.0.0')]
        end

        def dev_deps
          @dev_deps ||= []
        end

        def [](key)
          self.send(key.intern)
        end
      end # class GemJson
    end # module Fixtures

    def gem_json
      @gem_json ||= Fixtures::GemJson.new
    end
  end # module Test
end # module Polisher
