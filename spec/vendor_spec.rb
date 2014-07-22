# Polisher Vendor Specs
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/vendor'

module Polisher
  describe HasVendoredDeps do
    before(:each) do
      @obj = Object.new
      @obj.extend(HasVendoredDeps)
    end

    describe "#vendored_file_paths" do
      it "returns file marks in gem marked as vendored" do
        expected = [ 'vendor/foo.rb', 'vendor/bar/foo.rb']
        paths    = ['foo.rb'] + expected
        gem = Polisher::Gem.new
        gem.should_receive(:file_paths).and_return(paths)
        gem.vendored_file_paths.should == expected
      end
    end

    describe "#vendored" do
      it "returns list of vendored modules in gem" do
        gem = Polisher::Gem.new
        vendored = ['vendor/thor.rb', 'vendor/thor/foo.rb', 'vendor/biz/baz.rb']
        gem.should_receive(:vendored_file_paths).and_return(vendored)
        gem.vendored.should == {'thor' => nil, 'biz' => nil}
      end

      context "vendored module has VERSION.rb file" do
        it "returns version of vendored gems"
      end
    end

  end
end
