# Polisher RPM Requirement Specs
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/requirement'
require 'polisher/gem'

module Polisher::RPM
  describe Requirement do
    describe "#str" do
      it "returns requirement in string format" do
        req = described_class.new :name => 'rubygem(activesupport)'
        req.str.should == 'rubygem(activesupport)'

        req = described_class.new :name => 'rubygem(activesupport)',
                                  :condition => '>=', :version => '4.0'
        req.str.should == 'rubygem(activesupport) >= 4.0'
      end
    end

    describe "#specifier" do
      it "returns specifier in string format" do
        req = described_class.new :condition => '>=', :version => '10.0'
        req.specifier.should == '>= 10.0'
      end

      context "version is nil" do
        it "returns nil" do
          req = described_class.new
          req.specifier.should be_nil
        end
      end
    end

    describe "#parse" do
      it "parses requirement string" do
        req = described_class.parse "Requires: rubygem(foo)"
        req.br.should be_false
        req.name.should == "rubygem(foo)"
        req.gem_name.should == "foo"
        req.condition.should be_nil
        req.version.should be_nil

        req = described_class.parse "BuildRequires: rubygem(foo)"
        req.br.should be_true

        req = described_class.parse "rubygem(rake)"
        req.br.should be_false
        req.name.should == "rubygem(rake)"

        req = described_class.parse "rubygem(rake) < 5"
        req.condition.should == "<"
        req.version.should == "5"
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

    describe "#matches?" do
      context "requirement is same as dep requirement" do
        it "returns true"
      end

      context "requirement is not same as dep requirement" do
        it "returns false"
      end
    end

    describe "#gem?" do
      context "requirement matches gem dep matcher" do
        it "returns true" do
          described_class.parse("rubygem(rails)").gem?.should be_true
        end
      end

      context "requirement does not match gem dep matcher" do
        it "returns false" do
          described_class.parse("something").gem?.should be_false
        end
      end
    end

    describe "#gem_name" do
      it "returns gem name" do
        described_class.parse("rubygem(rails)").gem_name.should == "rails"
      end

      context "requirement is not a gem" do
        it "returns nil" do
          described_class.parse("something").gem_name.should be_nil
        end
      end
    end
  end # describe Requirement
end # module Polisher::RPM
