#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "#upstream_gem" do
      it "sets & returns upstream gem" do
        gem_name = 'polisher'
        version  = 5.0
        gem = Polisher::Gem.new
        Polisher::Gem.should_receive(:from_rubygems)
                     .with(gem_name, version)
                     .and_return(gem)
        spec = described_class.new :gem_name => gem_name, :version => version
        spec.upstream_gem.should == gem
        spec.upstream_gem.object_id.should == spec.upstream_gem.object_id
      end
    end
  end # describe Spec
end # module Polisher::RPM
