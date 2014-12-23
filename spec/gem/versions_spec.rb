#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
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
                       .and_return(['2.2', '1.1'])
        described_class.latest_version_of('polisher').should == '2.2'
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
  end # describe Gem
end # module Polisher
