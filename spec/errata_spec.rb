# Polisher Errata Spec
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'polisher/errata'

module Polisher
  describe Errata do
    describe "#versions_for" do
      before(:each) do
        @result = double(Curl::Easy.new)
        @result.should_receive(:body_str).and_return({'tag' => [['rubygem-rails-1.0.0-1']]}.to_json)
      end

      it "uses curl to retreive updates" do
        client = Curl::Easy.new
        described_class.should_receive(:client).with('http://errata.url/builds').and_return(client)
        client.should_receive(:get).and_return(@result)

        described_class.versions_for('http://errata.url', 'rails')
      end

      it "returns versions" do
        client = Curl::Easy.new
        described_class.should_receive(:client).and_return(client)
        client.should_receive(:get).and_return(@result)

        described_class.versions_for('http://errata.url', 'rails').should == ['1.0.0']
      end

      it "invokes block with versions" do
        client = Curl::Easy.new
        described_class.should_receive(:client).and_return(client)
        client.should_receive(:get).and_return(@result)

        cb = proc {}
        cb.should_receive(:call).with(:errata, 'rails', ['1.0.0'])
        described_class.versions_for('http://errata.url', 'rails', &cb)
      end
    end
  end # describe Koji
end # module Polisher
