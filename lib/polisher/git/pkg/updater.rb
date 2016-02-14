# Polisher Git Package Updater Mixin
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

module Polisher
  module Git
    module PkgUpdater
      def update_metadata(gem)
        @version = gem.version
      end

      # Update the local spec to the specified gem version
      def update_spec_to(gem, update_args={})
        in_repo do
          spec.update_to(gem, update_args)
          File.write(spec_file, spec.to_string)
          @dirty_spec = true
        end
      end

      # Generate new sources file
      def gen_sources_for(gem)
        require_dep! 'awesome_spawn'
        require_cmd! md5sum_cmd
        in_repo do
          AwesomeSpawn.run "#{md5sum_cmd} #{gem.gem_path} > sources"
          File.write('sources', File.read('sources').gsub("#{GemCache::DIR}/", ''))
        end
      end

      # Update git ignore to ignore gem
      def ignore(gem)
        in_repo do
          nl = File.exist?('.gitignore') ? "\n" : ''
          content = "#{nl}#{gem.name}-#{gem.version}.gem"
          File.open(".gitignore", 'a') { |f| f.write content }
        end
      end

      # Update the local pkg to specified gem
      #
      # @param [Polisher::Gem] gem instance of gem containing metadata to update to
      def update_to(gem, update_args={})
        update_metadata gem
        update_spec_to gem, update_args
        gen_sources_for gem
        ignore gem
        self
      end
    end # module PkgUpdate
  end # module Git
end # module Polisher
