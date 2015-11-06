#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "::download_gem" do
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

    describe "::from_rubygems" do
      it "downloads gem" do
        described_class.should_receive(:download_gem)
                       .with('polisher', '0.9')
                       .at_least(:once)
        described_class.should_receive(:from_gem)
        described_class.from_rubygems('polisher', '0.9')
      end

      it "returns instantiated gem" do
        described_class.should_receive(:download_gem)
                       .at_least(:once)
        gem = described_class.new
        described_class.should_receive(:from_gem)
                       .with(described_class.downloaded_gem_path('polisher', '0.9'))
                       .and_return(gem)
        described_class.from_rubygems('polisher', '0.9').should == gem
      end
    end

    describe "::download_gem_path" do
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

    describe "::retrieve" do
      it "returns gem retrieved from rubygems" do
        curl = Curl::Easy.new
        curl.should_receive(:http_get)
        curl.should_receive(:body_str).and_return('spec')
        described_class.instance_variable_set(:@client, curl)

        gem = described_class.new
        described_class.should_receive(:parse).with('spec').and_return(gem)

        described_class.retrieve('rails').should == gem

        url = "https://rubygems.org/api/v1/gems/rails.json"
        curl.url.should == url
      end
    end

    describe "#download_gem" do
      it "downloads gem specified by attributes" do
        described_class.should_receive(:download_gem)
                       .with('polisher', '0.8')
        described_class.new(:name => 'polisher', :version => '0.8').download_gem
      end
    end

    describe "#download_gem_path" do
      it "returns path of gem specified by attributes" do
        described_class.should_receive(:downloaded_gem_path)
                       .with('polisher', '0.8')
        described_class.new(:name => 'polisher', :version => '0.8').downloaded_gem_path
      end
    end
  end # describe Gem
end # module Polisher
