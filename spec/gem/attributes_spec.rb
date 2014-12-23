#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gem'

module Polisher
  describe Gem do
    describe "#file_name" do
      it "returns name-version.gem" do
        expected = 'rails-4.0.0.gem'
        Polisher::Gem.new(:name => 'rails', :version => '4.0.0')
                     .file_name.should == expected
      end
    end
  end # describe Gem
end # module Polisher
