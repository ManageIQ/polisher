# Polisher RPM Requirement Specs
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/requirement'

module Polisher::RPM
  describe Requirement do
    describe "#initialize" do
      it "sets requirement attributes" do
        req = described_class.new :name      => 'polisher ',
                                  :condition => '>',
                                  :version   => '5.0'
        req.name.should      == 'polisher'
        req.condition.should == '>'
        req.version.should   == '5.0'
      end
    end
  end # describe Requirement
end # module Polisher::RPM
