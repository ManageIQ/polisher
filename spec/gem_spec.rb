# Polisher Gem Specs
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "#initialize" do
      it "sets gemfile attributes" do
        gem = Polisher::Gem.new :name => 'rails',
                                :version => '4.0.0',
                                :deps => ['activesupport', 'activerecord'],
                                :dev_deps => ['rake']
        gem.name.should == 'rails'
        gem.version.should == '4.0.0'
        gem.deps.should == ['activesupport', 'activerecord']
        gem.dev_deps.should == ['rake']
      end
    end

    describe "#parse" do
      it "returns new gem" do
        gem = Polisher::Gem.parse
        gem.should be_an_instance_of(Polisher::Gem)
      end

      it "parses gem from gem spec" do
        spec = Polisher::Test::GEM_SPEC
        gem  = Polisher::Gem.parse(:gemspec => spec[:path])
        gem.name.should     == spec[:name]
        gem.version.should  == spec[:version]
        gem.deps.should     == spec[:deps]
        gem.dev_deps.should == spec[:dev_deps]
      end

      it "parses gem from gem at path"

      it "parses gem from metadata hash" do
        gemj = Polisher::Test::GEM_JSON
        gem = Polisher::Gem.parse gemj[:json]
        gem.name.should     == gemj[:name]
        gem.version.should  == gemj[:version]
        gem.deps.should     == gemj[:deps]
        gem.dev_deps.should == gemj[:dev_deps]
      end
    end

    describe "#retrieve" do
      before(:each) do
        @local_gem = Polisher::Test::LOCAL_GEM

        # stub out expected calls to curl
        @curl1 = Curl::Easy.new
        @curl2 = Curl::Easy.new

        Curl::Easy.should_receive(:http_get).with(@local_gem[:json_url]).and_return(@curl1)
        @curl1.should_receive(:body_str).and_return(@local_gem[:json])

        Curl::Easy.should_receive(:new).with(@local_gem[:url]).and_return(@curl2)
        @curl2.should_receive(:http_get)
        @curl2.should_receive(:body_str).and_return(@local_gem[:contents])
      end

      it "returns gem retrieved from rubygems" do
        gem = Polisher::Gem.retrieve(@local_gem[:name])
        gem.should be_an_instance_of(Polisher::Gem)
        gem.name.should     == @local_gem[:name]
        gem.version.should  == @local_gem[:version]
        gem.deps.should     == @local_gem[:deps]
        gem.dev_deps.should == @local_gem[:dev_deps]
      end

      it "sets gem files" do
        gem = Polisher::Gem.retrieve(@local_gem[:name])
        gem.should be_an_instance_of(Polisher::Gem)
        gem.files.should == @local_gem[:files]
      end
    end
  end # describe Gem
end # module Polisher
