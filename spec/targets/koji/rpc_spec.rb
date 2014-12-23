#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/targets/koji'

module Polisher
  describe Koji do
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
  end # describe Koji
end # module Polisher
