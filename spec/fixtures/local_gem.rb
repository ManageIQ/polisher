module Polisher
  module Test
    module Fixtures
      class LocalGem
        def name
          @name ||= 'rspec'
        end

        def version
          @version ||= '2.12.0'
        end

        def json_url
          @json_url ||= "https://rubygems.org/api/v1/gems/#{name}.json"
        end

        def json_path
          @json_path ||= "#{data_dir}/#{name}.json"
        end

        def json
          @json ||= File.read(json_path)
        end

        def gem_path
          @gem_contents_path ||= "#{data_dir}/#{name}-#{version}.gem"
        end

        def gem
          @gem ||= File.read(local_gem_contents_path)
        end

        def url
          @gem_url ||= "https://rubygems.org/gems/#{name}-#{version}.gem"
        end

        def deps
          @deps ||= [::Gem::Dependency.new('rspec-core',         '~> 2.14.0'),
                     ::Gem::Dependency.new('rspec-expectations', '~> 2.14.0'),
                     ::Gem::Dependency.new('rspec-mocks',        '~> 2.14.0')]
        end

        def dev_deps
          @dev_deps ||= []
        end

        def files
          @files ||= ['License.txt', 'README.md', 'lib', 'lib/rspec',
                      'lib/rspec/version.rb', 'lib/rspec.rb']
        end

        def [](key)
          self.send(key.intern)
        end
      end # class LocalGem
    end # module Fixtures

    def local_gem
      @local_gem ||= Fixtures::LocalGem.new
    end
  end # module Test
end # module Polisher
