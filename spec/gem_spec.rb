# Polisher Gem Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "#file_name" do
      it "returns name-version.gem" do
        expected = 'rails-4.0.0.gem'
        Polisher::Gem.new(:name => 'rails', :version => '4.0.0')
                     .file_name.should == expected
      end
    end

    describe "#initialize" do
      it "sets gem attributes" do
        gem = described_class.new :name     => 'rails',
                                  :version  => '4.0.0',
                                  :deps     => %w(activesupport activerecord),
                                  :dev_deps => ['rake']
        gem.name.should == 'rails'
        gem.version.should == '4.0.0'
        gem.deps.should == ['activesupport', 'activerecord']
        gem.dev_deps.should == ['rake']
      end
    end

    describe "#ignorable_file?" do
      context "args matches an ignorable file" do
        it "returns true" do
          described_class.ignorable_file?('foo.gemspec').should be_true
          described_class.ignorable_file?('Gemfile').should be_true
        end
      end

      context "args does not match an ignorable file" do
        it "returns false" do
          described_class.ignorable_file?('.rvmra').should be_false
          described_class.ignorable_file?('foo.gemspoc').should be_false
        end
      end
    end

    describe "#doc_file?" do
      context "file is on doc file list" do
        it "returns true" do
          described_class.doc_file?('CHANGELOG').should be_true
        end
      end

      context "file is not on doc file list" do
        it "returns false" do
          described_class.doc_file?('foobar.rb').should be_false
        end
      end
    end

    describe "#has_file_satisfied_by?" do
      context "specified spec file satisfies at least one gem file" do
        it "returns true" do
          spec_file = 'spec_file'
          gem_file  = 'gem_file'
          RPM::Spec.should_receive(:file_satisfies?)
                   .with(spec_file, gem_file)
                   .and_return(true)

          gem = Polisher::Gem.new
          gem.should_receive(:file_paths).and_return([gem_file])
          gem.has_file_satisfied_by?(spec_file).should be_true
        end
      end

      context "specified spec file does not satisfy any gem files" do
        it "returns false" do
          spec_file = 'spec_file'
          gem_file  = 'gem_file'
          RPM::Spec.should_receive(:file_satisfies?)
                   .with(spec_file, gem_file)
                   .and_return(false)

          gem = Polisher::Gem.new
          gem.should_receive(:file_paths).and_return([gem_file])
          gem.has_file_satisfied_by?(spec_file).should be_false
        end
      end
    end

    describe "#local_versions_for" do
      before(:each) do
        # XXX clear the cached version of the gem specification db
        described_class.instance_variable_set(:@local_db, nil)

        gem1 = ::Gem::Specification.new 'rake', '1.0'
        gem2 = ::Gem::Specification.new 'rake', '2.0'
        gem3 = ::Gem::Specification.new 'rails', '3.0'
        ::Gem::Specification.should_receive(:all).and_return([gem1, gem2, gem3])

        @version1 = ::Gem::Version.new '1.0'
        @version2 = ::Gem::Version.new '2.0'
      end

      it "returns versions of specified gem in local db" do
        described_class.local_versions_for('rake').should == [@version1, @version2]
      end

      it "invokes cb with versions retrieved" do
        cb = proc {}
        cb.should_receive(:call).with(:local_gem, 'rake', [@version1, @version2])
        described_class.local_versions_for('rake', &cb)
      end
    end

    describe "#parse" do
      it "returns new gem" do
        gem = described_class.parse
        gem.should be_an_instance_of(described_class)
      end

      it "parses gem from gem spec" do
        spec = Polisher::Test::GEM_SPEC
        gem  = described_class.parse(:gemspec => spec[:path])
        gem.name.should     == spec[:name]
        gem.version.should  == spec[:version]
        gem.deps.should     == spec[:deps]
        gem.dev_deps.should == spec[:dev_deps]
      end

      it "parses gem from gem at path"

      it "parses gem from metadata hash" do
        gemj = Polisher::Test::GEM_JSON
        gem = described_class.parse gemj[:json]
        gem.name.should     == gemj[:name]
        gem.version.should  == gemj[:version]
        gem.deps.should     == gemj[:deps]
        gem.dev_deps.should == gemj[:dev_deps]
      end
    end

    describe "#remote_versions_for" do
      it "retrieves versions from rubygems.org" do
        curl = Curl::Easy.new
        described_class.should_receive(:client)
                       .at_least(:once).and_return(curl)
        curl.should_receive(:http_get)

        # actual output too verbose, just including bits we need
        curl.should_receive(:body_str)
            .and_return([{'number' => 1.1}, {'number' => 2.2}].to_json)
        described_class.remote_versions_for('polisher').should == [1.1, 2.2]
        curl.url.should == "https://rubygems.org/api/v1/versions/polisher.json"
      end
    end

    describe "#lastest_version_of" do
      it "retrieves latests version of gem available on rubygems.org" do
        described_class.should_receive(:remote_versions_for)
                       .with('polisher')
                       .and_return([2.2, 1.1])
        described_class.latest_version_of('polisher').should == 2.2
      end
    end

    describe "#download_gem" do
      context "gem in GemCache" do
        it "returns GemCache gem" do
          gem = described_class.new
          GemCache.should_receive(:get).with('polisher', '1.1')
                                       .and_return(gem)
          described_class.download_gem('polisher', '1.1').should == gem
        end
      end

      it "uses curl to download gem" do
        GemCache.should_receive(:get).and_return(nil)
        curl = Curl::Easy.new
        described_class.should_receive(:client)
                       .at_least(:once).and_return(curl)
        curl.should_receive(:http_get)
        curl.should_receive(:body_str).and_return('') # stub out body_str

        described_class.download_gem 'polisher', '2.2'
        curl.url.should == "https://rubygems.org/gems/polisher-2.2.gem"
      end

      it "sets gem in gem cache" do
        GemCache.should_receive(:get).and_return(nil)
        curl = Curl::Easy.new
        described_class.should_receive(:client)
                       .at_least(:once).and_return(curl)
        curl.stub(:http_get) # stub out http_get
        curl.should_receive(:body_str).and_return('gem')
        GemCache.should_receive(:set)
                .with('polisher', '1.1', 'gem')
        described_class.download_gem 'polisher', '1.1'
      end

      it "returns downloaded gem binary contents" do
        GemCache.should_receive(:get).and_return(nil)
        curl = Curl::Easy.new
        described_class.should_receive(:client)
                       .at_least(:once).and_return(curl)
        curl.stub(:http_get) # stub out http_get
        curl.should_receive(:body_str).and_return('gem')
        described_class.download_gem('polisher', '1.1').should == 'gem'
      end
    end

    describe "#download_gem_path" do
      it "downloads gem" do
        gem = described_class.new
        described_class.should_receive(:download_gem)
        gem.downloaded_gem_path
      end

      it "returns gem cache path for gem" do
        # stub out d/l
        gem = described_class.new :name => 'rails', :version => '1.0'
        described_class.should_receive(:download_gem)
        Polisher::GemCache.should_receive(:path_for)
                          .with('rails', '1.0')
                          .at_least(:once)
                          .and_return('rails_path')
        gem.downloaded_gem_path.should == 'rails_path'
      end
    end

    describe "#gem_path" do
      it "returns specified path" do
        gem = described_class.new :path => 'gem_path'
        gem.gem_path.should == 'gem_path'
      end

      context "specified path is null" do
        it "returns downloaded gem path" do
          gem = described_class.new
          gem.should_receive(:downloaded_gem_path).and_return('gem_path')
          gem.gem_path.should == 'gem_path'
        end
      end
    end

    describe "#unpack" do
      it "unpacks gem at gem_path into temp dir"
      it "returns tmp dir"
      context "block specified" do
        it "invokes block with tmp dir"
        it "removes tmp dir"
        it "returns nil"
      end
    end

    describe "#file_paths" do
      it "returns list of file paths in gem" do
        gem = described_class.new
        gem.should_receive(:each_file).and_yield('file1').and_yield('file2')
        gem.file_paths.should == %w(file1 file2)
      end
    end

    describe "#retrieve" do
      it "returns gem retrieved from rubygems" do
        curl = Curl::Easy.new
        curl.should_receive(:body_str).and_return('spec')

        url = "https://rubygems.org/api/v1/gems/rails.json"
        Curl::Easy.should_receive(:http_get).with(url).and_return(curl)

        gem = described_class.new
        described_class.should_receive(:parse).with('spec').and_return(gem)

        described_class.retrieve('rails').should == gem
      end
    end

    describe "#versions" do
      it "looks up and returns versions of gem" do
        gem = described_class.new :name => 'rails'
        Polisher::VersionChecker.should_receive(:versions_for)
                                .with('rails')
                                .and_return(:koji => ['1.1.1'])
        gem.versions.should == {'rails' => {:koji => ['1.1.1']}}
      end

      context "recursive is true" do
        it "retrieves dependency versions" do
          # stub out version checker
          retrieved = {:koji => ['1.0']}
          Polisher::VersionChecker.should_receive(:versions_for)
                                  .and_return(retrieved)

          versions = {}
          gem = described_class.new :name => 'rails'
          gem.should_receive(:dependency_versions)
             .with(:recursive => true, :versions => {'rails' => retrieved})
             .and_call_original
          gem.versions(:recursive => true, :versions => versions)
             .should == {'rails' => {:koji => ['1.0']}}
        end

        context "dev_deps is true" do
          it "retrieves dev dependency versions" do
            # stub out version checker
            retrieved = {:koji => ['1.0']}
            Polisher::VersionChecker.should_receive(:versions_for)
                                    .and_return(retrieved)

            versions = {}
            gem = described_class.new :name => 'rails'
            gem.should_receive(:dependency_versions)
               .with(:recursive => true, :dev_deps => true,
                      :versions => {'rails' => retrieved})
               .and_call_original
            gem.should_receive(:dependency_versions)
               .with(:recursive => true, :dev => true, :dev_deps => true,
                      :versions => {'rails' => retrieved})
               .and_call_original
            gem.versions(:recursive => true, :dev_deps => true,
                         :versions => versions)
               .should == {'rails' => {:koji => ['1.0']}}
          end
        end
      end
    end

    describe "#dependency_versions" do
      it "retrieves dependency versions" do
        gem = described_class.new
        gem.should_receive(:deps).and_return([::Gem::Dependency.new('rake')])
        described_class.should_receive(:retrieve)
                       .with('rake').and_return(gem)

        versions = {'rake' => {:koji => ['2.1']}}
        gem.should_receive(:versions).and_return(versions)
        gem.dependency_versions.should == versions
      end

      it "retrieves dev dependency versions" do
        gem = described_class.new
        gem.should_receive(:dev_deps).and_return([::Gem::Dependency.new('rake')])
        described_class.should_receive(:retrieve)
                       .with('rake').and_return(gem)

        versions = {'rake' => {:koji => ['2.1']}}
        gem.should_receive(:versions).and_return(versions)
        gem.dependency_versions(:dev => true).should == versions
      end

      context "error during gem or version retrieval" do
        it "sets version to 'unknown'" do
          gem = described_class.new
          gem.should_receive(:deps).and_return([::Gem::Dependency.new('rake')])
          described_class.should_receive(:retrieve)
                         .with('rake').and_raise(RuntimeError)

          versions = {:all => [:unknown]}
          gem.should_not_receive(:versions)
          Polisher::VersionChecker.should_receive(:unknown_version)
                                  .with(:all, 'rake')
                                  .and_return(versions)
          gem.dependency_versions.should == {'rake' => versions}
        end
      end
    end

    describe "#diff" do
      before(:each) do
        @gem1 = described_class.new
        @gem2 = described_class.new

        @result = AwesomeSpawn::CommandResult.new '', 'diff_out', '', 0
      end

      it "runs diff against unpacked local and other gems and returns output" do
        @gem1.should_receive(:unpack).and_return('dir1')
        @gem2.should_receive(:unpack).and_return('dir2')
        AwesomeSpawn.should_receive(:run)
          .with("#{Polisher::Gem.diff_cmd} -r dir1 dir2")
          .and_return(@result)
        @gem1.diff(@gem2).should == @result.output
      end

      it "removes unpacked gem dirs" do
        @gem1.should_receive(:unpack).and_return('dir1')
        @gem2.should_receive(:unpack).and_return('dir2')
        AwesomeSpawn.should_receive(:run).and_return(@result)
        FileUtils.should_receive(:rm_rf).with('dir1')
        FileUtils.should_receive(:rm_rf).with('dir2')
        # XXX for the GemCache dir cleaning:
        FileUtils.should_receive(:rm_rf).at_least(:once)
        @gem1.diff(@gem2)
      end

      context "error during operations" do
        it "removes unpacked gem dirs" do
          @gem1.should_receive(:unpack).and_return('dir1')
          @gem2.should_receive(:unpack).and_return('dir2')
          AwesomeSpawn.should_receive(:run).
            and_raise(AwesomeSpawn::CommandResultError.new('', ''))
          FileUtils.should_receive(:rm_rf).with('dir1')
          FileUtils.should_receive(:rm_rf).with('dir2')
          FileUtils.should_receive(:rm_rf).at_least(:once)
          @gem1.diff(@gem2)
        end
      end
    end

  end # describe Gem
end # module Polisher
