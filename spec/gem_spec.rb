# Polisher Gem Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "#initialize" do
      it "sets gem attributes" do
        gem = described_class.new :name     => 'rails',
                                  :version  => '4.0.0',
                                  :deps     => %w(activesupport activerecord),
                                  :dev_deps => ['rake']
        gem.name.should == 'rails'
        gem.version.should == '4.0.0'
        gem.deps.should == ['activesupport', 'activerecord']
        gem.dev_deps.should == ['rake']
      end
    end

    describe "#gem_path" do
      it "returns specified path" do
        gem = described_class.new :path => 'gem_path'
        gem.gem_path.should == 'gem_path'
      end

      context "specified path is null" do
        it "returns downloaded gem path" do
          gem = described_class.new
          gem.should_receive(:downloaded_gem_path).and_return('gem_path')
          gem.gem_path.should == 'gem_path'
        end
      end
    end
  end # describe Gem
end # module Polisher
