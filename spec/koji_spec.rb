# Polisher Koji Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/koji'

module Polisher
  describe Koji do
    describe "::has_build?" do
      context "retrieved versions includes the specified version" do
        it "returns true" do
          described_class.should_receive(:versions_for).and_return(['1.0.0'])
          described_class.has_build?('foobar', '1.0.0').should be_true
        end
      end

      context "retrieved versions does not include the specified version" do
        it "returns false" do
          described_class.should_receive(:versions_for).and_return(['1.0.1'])
          described_class.has_build?('foobar', '1.0.1').should be_true
        end
      end
    end

    describe "#has_build_satisfying?" do
      context "retrieved versions satisfy the specified dependency" do
        it "returns true" do
          described_class.should_receive(:versions_for).and_return(['1.0.0'])
          described_class.has_build_satisfying?('foobar', '> 0.9.0').should be_true
        end
      end

      context "retrieved versions does not satisfy the specified dependency" do
        it "returns false" do
          described_class.should_receive(:versions_for).and_return(['1.0.0'])
          described_class.has_build_satisfying?('foobar', '< 0.9.0').should be_false
        end
      end
    end

    describe "#tagged_in" do
      before(:each) do
        @client = double(XMLRPC::Client)
        described_class.should_receive(:client).and_return(@client)
      end

      it "uses xmlrpc client to retrieve packages" do
        expected = ['listPackages', nil, nil, "rubygem-rails", nil, false, true]
        @client.should_receive(:call).with(*expected).and_return([])
        described_class.tagged_in 'rails'
      end

      it "returns tags" do
        tags = [{'tag_name' => 'tag1'}, {'tag_name' => 'tag2'}]
        @client.should_receive(:call).and_return(tags)
        described_class.tagged_in('rails').should == ['tag1', 'tag2']
      end
    end

    describe ".diff" do
      it "includes updated, added, deleted, unchanged rpms" do
        VCR.use_cassette('koji_diff_f19ruby_f21ruby') do
          results = Polisher::Koji.diff("f19-ruby", "f21-ruby")

          # updated
          results["rubygem-sqlite3"]["f19-ruby"].should == "1.3.5"
          results["rubygem-sqlite3"]["f21-ruby"].should == "1.3.8"

          # added
          results["rubygem-bcrypt"]["f19-ruby"].should be_nil
          results["rubygem-bcrypt"]["f21-ruby"].should == "3.1.7"

          # deleted
          results["rubygem-snmp"]["f19-ruby"].should == "1.1.0"
          results["rubygem-snmp"]["f21-ruby"].should be_nil

          # unchanged
          results["rubygem-RedCloth"]["f19-ruby"].should == "4.2.9"
          results["rubygem-RedCloth"]["f21-ruby"].should == "4.2.9"

          # f19 has 1.3.4 and 1.3.5
          results["rubygem-sinatra"]["f19-ruby"].should == "1.3.5"
        end
      end

      it ".tagged_build_additions" do
        VCR.use_cassette("#{described_class.name.underscore}.tagged_build_additions") do
          results = Polisher::Koji.tagged_build_additions("f19-ruby", "f21-ruby")

          results.keys.length.should == 57
          results["xchat-ruby"]["f21-ruby"].should == "1.2"
          results["weechat"]["f21-ruby"].should    == "0.4.3"
        end
      end

      it ".tagged_build_removals" do
        VCR.use_cassette("#{described_class.name.underscore}.tagged_build_removals") do
          results = Polisher::Koji.tagged_build_removals("f19-ruby", "f21-ruby")

          results.keys.length.should == 182
          results["rubygem-webrat"].should      == {"f19-ruby" => "0.7.3"}
          results["rubygem-rspec-rails"].should == {"f19-ruby" => "2.12.0"}
        end
      end

      it ".tagged_build_changed_overlaps" do
        VCR.use_cassette("#{described_class.name.underscore}.tagged_build_changed_overlaps") do
          results = Polisher::Koji.tagged_build_changed_overlaps("f19-ruby", "f21-ruby")

          results.keys.length.should == 31
          results["rubygem-rails"].should ==    {"f19-ruby" => "3.2.12", "f21-ruby" => "4.1.0"}
          results["rubygem-nokogiri"].should == {"f19-ruby" => "1.5.6", "f21-ruby"  => "1.6.1"}
        end
      end

      it ".tagged_build_unchanged_overlaps" do
        VCR.use_cassette("#{described_class.name.underscore}.tagged_build_unchanged_overlaps") do
          results = Polisher::Koji.tagged_build_unchanged_overlaps("f19-ruby", "f21-ruby")

          results.keys.length.should == 9
          results["rubygem-thin"].should ==    {"f19-ruby" => "1.5.0",  "f21-ruby" => "1.5.0"}
          results["rubygem-gherkin"].should == {"f19-ruby" => "2.11.6", "f21-ruby" => "2.11.6"}
        end
      end
    end

    describe "#versions_for" do
      before(:each) do
        @client = double(XMLRPC::Client)
        described_class.should_receive(:client).at_least(:once).and_return(@client)
      end

      it "uses xmlrpc client to retreive versions" do
        expected = ['listTagged', described_class.koji_tag, nil, true,
                    nil, false, "rubygem-rails"]
        @client.should_receive(:call).with(*expected).and_return([])
        described_class.versions_for 'rails'
      end

      it "handles multiple koji tags" do
        described_class.should_receive(:koji_tags).and_return(['tag1', 'tag2'])
        expected1 = ['listTagged', 'tag1', nil, true,
                     nil, false, "rubygem-rails"]
        expected2 = ['listTagged', 'tag2', nil, true,
                     nil, false, "rubygem-rails"]
        @client.should_receive(:call).with(*expected1).and_return([])
        @client.should_receive(:call).with(*expected2).and_return([])
        described_class.versions_for 'rails'
      end

      it "handles multiple koji prefixes" do
        @prefix = ['rubygem-', 'ruby193-rubygem-']
        described_class.should_receive(:package_prefix).twice.and_return(['rubygem-', 'ruby193-rubygem-'])
        described_class.should_receive(:koji_tags).and_return(['tag1', 'tag2'])
        expected1 = ['listTagged', 'tag1', nil, true,
                     nil, false, "rubygem-rails"]
        expected2 = ['listTagged', 'tag2', nil, true,
                     nil, false, "rubygem-rails"]
        expected3 = ['listTagged', 'tag1', nil, true,
                     nil, false, "ruby193-rubygem-rails"]
        expected4 = ['listTagged', 'tag2', nil, true,
                     nil, false, "ruby193-rubygem-rails"]
        @client.should_receive(:call).with(*expected1).and_return([])
        @client.should_receive(:call).with(*expected2).and_return([])
        @client.should_receive(:call).with(*expected3).and_return([])
        @client.should_receive(:call).with(*expected4).and_return([])
        described_class.versions_for 'rails'
      end

      it "returns versions" do
        versions = [{'version' => '1.0.0'}]
        @client.should_receive(:call).and_return(versions)
        described_class.versions_for('rails').should == ['1.0.0']
      end

      it "invokes block with versions" do
        versions = [{'version' => '1.0.0'}]
        @client.should_receive(:call).and_return(versions)

        cb = proc {}
        cb.should_receive(:call).with(:koji, 'rails', ['1.0.0'])
        described_class.versions_for('rails', &cb)
      end
    end # describe versions_for

    describe "#build" do
      it "runs build_cmd" do
        result = AwesomeSpawn::CommandResult.new "", "", "", 0
        expected = "#{described_class.build_cmd} build  #{described_class.build_tgt} srpm"
        AwesomeSpawn.should_receive(:run).with(expected).and_return(result)
        described_class.should_receive(:require_cmd!)
                       .with(described_class.build_cmd).and_return(true)
        described_class.build :srpm => 'srpm'
      end

      it "runs scratch build" do
        described_class.should_receive(:require_cmd!)
                       .with(described_class.build_cmd).and_return(true)
        result = AwesomeSpawn::CommandResult.new "", "", "", 0
        expected = "#{described_class.build_cmd} build --scratch f20 srpm"
        AwesomeSpawn.should_receive(:run).with(expected).and_return(result)
        described_class.build :target => 'f20', :srpm => 'srpm', :scratch => true
      end

      it "parses & returns url from build output" do
        described_class.should_receive(:require_cmd!).and_return(true)
        result = AwesomeSpawn::CommandResult.new "", "output", "", 0
        AwesomeSpawn.should_receive(:run).and_return(result)
        described_class.should_receive(:parse_url).with('output').and_return('url')
        described_class.build.should == 'url'
      end

      describe "non-zero build exit status" do
        it "raises runtime error with build url" do
          described_class.should_receive(:require_cmd!).and_return(true)
          result = AwesomeSpawn::CommandResult.new "", "", "", 1
          AwesomeSpawn.should_receive(:run).and_return(result)
          described_class.should_receive(:parse_url).and_return('url')
          lambda { described_class.build }.should raise_error(RuntimeError, 'url')
        end
      end
    end
  end # describe Koji
end # module Polisher
