#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'
require 'polisher/rpm/requirement'

module Polisher::RPM
  describe Requirement do
    describe "#==" do
      context "requirements are equal" do
        it "returns true" do
          req1 = described_class.new
          req2 = described_class.new
          req1.should == req2

          req1 = described_class.parse 'rubygem(rails)'
          req2 = described_class.parse 'rubygem(rails)'
          req1.should == req2

          req1 = described_class.parse 'rubygem(rails) >= 1.0.0'
          req2 = described_class.parse 'rubygem(rails) >= 1.0.0'
          req1.should == req2
        end
      end

      context "requirements are not equal" do
        it "returns true" do
          req1 = described_class.parse 'rubygem(rails)'
          req2 = described_class.parse 'rubygem(rake)'
          req1.should_not == req2

          req1 = described_class.parse 'rubygem(rake) > 1'
          req2 = described_class.parse 'rubygem(rake) > 2'
          req1.should_not == req2
        end
      end
    end

    describe "#gcd" do
      it "selects / returns max version less than local version" do
        req = described_class.new :version => "5.0.0"
        req.gcd(['1.0', '2.0', '5.0', '5.1', '6.1']).should == '2.0'
      end
    end

    describe "#min_satisfying_version" do
      context "no version req" do
        it "returns 0" do
          req = described_class.new
          req.min_satisfying_version.should == "0.0"
        end
      end

      context "= req" do
        it "returns local version" do
          req = described_class.new :condition => '=', :version => '5.0.0'
          req.min_satisfying_version.should == '5.0.0'
        end
      end

      context "> req" do
        it "returns next version" do
          req = described_class.new :condition => '>', :version => '5.0.0'
          req.min_satisfying_version.should == '5.0.1'
        end
      end

      context ">= req" do
        it "returns local version" do
          req = described_class.new :condition => '>=', :version => '5.0.0'
          req.min_satisfying_version.should == '5.0.0'
        end
      end

      context "< req" do
        it "returns 0" do
          req = described_class.new :condition => '<', :version => '5.0.0'
          req.min_satisfying_version.should == "0.0"
        end
      end

      context "<= req" do
        it "returns 0" do
          req = described_class.new :condition => '<=', :version => '5.0.0'
          req.min_satisfying_version.should == "0.0"
        end
      end
    end

    describe "#max_version_satisfying" do
      context "no version req" do
        it "returns infinity" do
          req = described_class.new
          req.max_satisfying_version.should == Float::INFINITY
        end
      end

      context "= req" do
        it "returns version" do
          req = described_class.new :condition => '=', :version => '1.2.3'
          req.max_satisfying_version.should == '1.2.3'
        end
      end

      context "> req" do
        it "returns infinity" do
          req = described_class.new :condition => '>', :version => '1.2.3'
          req.max_satisfying_version.should == Float::INFINITY
        end
      end

      context ">= req" do
        it "returns infinity" do
          req = described_class.new :condition => '>=', :version => '1.2.3'
          req.max_satisfying_version.should == Float::INFINITY
        end
      end

      context "< req" do
        context "versions list not specified" do
          it "raises argument error" do
            req = described_class.new :condition => '<', :version => '1.2.3'
            lambda {
              req.max_satisfying_version
            }.should raise_error(ArgumentError)
          end
        end

        it "returns gcd of list" do
          req = described_class.new :condition => '<', :version => '1.2.3'
          req.should_receive(:gcd).and_return('3')
          req.max_satisfying_version(['1', '2']).should == '3'
        end
      end

      context "<= req" do
        it "returns version" do
          req = described_class.new :condition => '<=', :version => '1.2.3'
          req.max_satisfying_version.should == '1.2.3'
        end
      end
    end

    describe "#min_failing_version" do
      context "no version req" do
        it "raises argument error" do
          req = described_class.new
          lambda{
            req.min_failing_version
          }.should raise_error(ArgumentError)
        end
      end

      context "= req" do
        it "returns next version" do
          req = described_class.new :condition => '=', :version => '5.0.0'
          req.min_failing_version.should == '5.0.1'
        end
      end

      context "> req" do
        it "returns 0" do
          req = described_class.new :condition => '>', :version => '5.0.0'
          req.min_failing_version.should == '0.0'
        end
      end

      context ">= req" do
        it "returns 0" do
          req = described_class.new :condition => '>=', :version => '5.0.0'
          req.min_failing_version.should == '0.0'
        end
      end

      context "< req" do
        it "returns version" do
          req = described_class.new :condition => '<', :version => '5.0.0'
          req.min_failing_version.should == '5.0.0'
        end
      end

      context "<= req" do
        it "returns next version" do
          req = described_class.new :condition => '<=', :version => '5.0.0'
          req.min_failing_version.should == '5.0.1'
        end
      end
    end

    describe "#max_failing_version" do
      context "no version req" do
        it "raises argument error" do
          req = described_class.new
          lambda {
            req.max_failing_version
          }.should raise_error(ArgumentError)
        end
      end

      context "= req" do
        context "versions are nil" do
          it "raises ArgumentError" do
            req = described_class.new :condition => '=', :version => '2.0'
            lambda {
              req.max_failing_version
            }.should raise_error(ArgumentError)
          end
        end

        it "returns gcd of list" do
          req = described_class.new :condition => '=', :version => '2.0'
          req.should_receive(:gcd).and_return('abc')
          req.max_failing_version(['1.2']).should == 'abc'
        end
      end

      context "> req" do
        it "returns version" do
          req = described_class.new :condition => '>', :version => '2.0'
          req.max_failing_version.should == '2.0'
        end
      end

      context ">= req" do
        context "versions are nil" do
          it "raises ArgumentError" do
            req = described_class.new :condition => '>=', :version => '2.0'
            lambda {
              req.max_failing_version
            }.should raise_error(ArgumentError)
          end
        end

        it "returns gcd of list" do
          req = described_class.new :condition => '>=', :version => '2.0'
          req.should_receive(:gcd).and_return('abc')
          req.max_failing_version(['1.2']).should == 'abc'
        end
      end

      context "< req" do
        it "raises argument error" do
          req = described_class.new :condition => '<', :version => '2.0'
          lambda {
            req.max_failing_version
          }.should raise_error(ArgumentError)
        end
      end

      context "<= req" do
        it "raises argument error" do
          req = described_class.new :condition => '<', :version => '2.0'
          lambda {
            req.max_failing_version
          }.should raise_error(ArgumentError)
        end
      end
    end

    describe "#matches?" do
      context "requirement is same as dep requirement" do
        it "returns true" do
          dep = ::Gem::Dependency.new 'rails',  '~> 1.0.0'
          req = described_class.new :name      => 'rubygem(rails)',
                                    :condition => '=>',
                                    :version   => '1.0.0'
          req.matches?(dep).should be_true

          req.condition = '<'
          req.version = '1.1'
          req.matches?(dep).should be_true
        end
      end

      context "requirement is not same as dep requirement" do
        it "returns false" do
          dep = ::Gem::Dependency.new 'rails'
          req = described_class.new :name => 'rake'

          req.matches?(dep).should be_false
        end
      end
    end
  end # describe Requirement
end # module Polisher::RPM
