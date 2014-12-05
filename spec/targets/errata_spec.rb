# Polisher Errata Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/targets/errata'

module Polisher
  describe Errata do
    describe "#versions_for" do
      before(:each) do
        @result = {'tag' => [['rubygem-rails-1.0.0-1']]}.to_json
        @orig_url = described_class.advisory_url
      end

      after(:each) do
        described_class.advisory_url @orig_url
        described_class.clear!
      end

      it "uses curl to retreive updates" do
        client = Curl::Easy.new
        described_class.should_receive(:client).at_least(:once).and_return(client)
        client.should_receive(:url=).with('http://errata.url/builds')
        client.should_receive(:get)
        client.should_receive(:body_str).and_return(@result)

        described_class.advisory_url 'http://errata.url'
        described_class.versions_for('rails')
      end

      it "returns versions" do
        client = Curl::Easy.new
        described_class.should_receive(:client).at_least(:once).and_return(client)
        client.stub(:get)
        client.should_receive(:body_str).and_return(@result)
        described_class.versions_for('rails').should == ['1.0.0']
      end

      it "invokes block with versions" do
        client = Curl::Easy.new
        described_class.should_receive(:client).at_least(:once).and_return(client)
        client.stub(:get)
        client.should_receive(:body_str).and_return(@result)

        cb = proc {}
        cb.should_receive(:call).with(:errata, 'rails', ['1.0.0'])
        described_class.versions_for('rails', &cb)
      end
    end
  end # describe Errata
end # module Polisher
