#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "#compare" do
      it "returns requirements in spec but not in gem" do
        req  = Requirement.parse 'rubygem(rails) > 3.0.0'
        spec = described_class.new :requires => [req]
        gem  = Polisher::Gem.new

        spec.compare(gem).should ==
          {:same => {}, :diff => {'rails' =>
                  {:spec => '> 3.0.0', :upstream => nil}}}
      end

      it "returns requirements in gem but not in spec" do
        req = ::Gem::Dependency.new('rails', '> 3.0.0')
        spec = described_class.new
        gem  = Polisher::Gem.new :deps => [req]

        spec.compare(gem).should ==
          {:same => {}, :diff => {'rails' =>
                  {:spec => nil, :upstream => '> 3.0.0'}}}
      end

      it "returns shared requirements with different specifiers" do
        greq = ::Gem::Dependency.new('rails', '< 5.0.0')
        gem  = Polisher::Gem.new :deps => [greq]

        sreq = Requirement.parse 'rubygem(rails) > 3.0.0'
        spec = described_class.new :requires => [sreq]

        spec.compare(gem).should ==
          {:same => {}, :diff => {'rails' =>
                  {:spec => '> 3.0.0', :upstream => '< 5.0.0'}}}
      end

      it "returns shared requirements" do
        greq = ::Gem::Dependency.new('rails', '< 3.0.0')
        gem  = Polisher::Gem.new :deps => [greq]

        sreq = Requirement.parse 'rubygem(rails) < 3.0.0'
        spec = described_class.new :requires => [sreq]

        spec.compare(gem).should ==
          {:diff => {}, :same => {'rails' =>
                  {:spec => '< 3.0.0', :upstream => '< 3.0.0'}}}
      end
    end
  end # describe Spec
end # module Polisher::RPM
