# Polisher Upstream Spec
#
# Licensed under the MIT license
# Copyright (C) 2013 Red Hat, Inc.

require 'polisher/upstream'

module Polisher
  describe Upstream do
    describe "#parse" do
      context "gem specified" do
        it "uses Polisher::Gem to parse gem" do
          path = "/foo.gem"
          gem  = Polisher::Gem.new
          Polisher::Gem.should_receive(:parse).with(:gem => path).and_return(gem)
          Polisher::Upstream.parse(path).should == gem
        end
      end

      context "gem spec specified" do
        it "uses Polisher::Gem to parse gemspec" do
          path = "/foo.gemspec"
          gem  = Polisher::Gem.new
          Polisher::Gem.should_receive(:parse).with(:gemspec => path).and_return(gem)
          Polisher::Upstream.parse(path).should == gem
        end
      end

      context "gemfile specified" do
        it "uses Polisher::GemFile to parse gemfile" do
          path = "/Gemfile"
          gemfile  = Polisher::Gemfile.new
          Polisher::Gemfile.should_receive(:parse).with(path).and_return(gemfile)
          Polisher::Upstream.parse(path).should == gemfile
        end
      end
    end
  end # describe Gemfile
end # module Polisher
