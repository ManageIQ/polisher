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
        described_class.build :srpm => 'srpm'
      end

      it "runs scratch build" do
        result = AwesomeSpawn::CommandResult.new "", "", "", 0
        expected = "#{described_class.build_cmd} build --scratch f20 srpm"
        AwesomeSpawn.should_receive(:run).with(expected).and_return(result)
        described_class.build :target => 'f20', :srpm => 'srpm', :scratch => true
      end

      it "parses & returns url from build output" do
        result = AwesomeSpawn::CommandResult.new "", "output", "", 0
        AwesomeSpawn.should_receive(:run).and_return(result)
        described_class.should_receive(:parse_url).with('output').and_return('url')
        described_class.build.should == 'url'
      end

      describe "non-zero build exit status" do
        it "raises runtime error with build url" do
          result = AwesomeSpawn::CommandResult.new "", "", "", 1
          AwesomeSpawn.should_receive(:run).and_return(result)
          described_class.should_receive(:parse_url).and_return('url')
          lambda { described_class.build }.should raise_error(RuntimeError, 'url')
        end
      end
    end
  end # describe Koji
end # module Polisher
