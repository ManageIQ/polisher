#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "#subpkg_containing" do
      it "returns subpackage containing specified file" do
        spec = described_class.new :pkg_files => {'foo' => ['file1']}
        spec.subpkg_containing('file1').should == 'foo'
      end

      context "no subpackage contains specified file" do
        it "returns nil" do
          spec = described_class.new :pkg_files => {}
          spec.subpkg_containing('anything').should be_nil
        end
      end
    end
  end # describe Spec
end # module Polisher::RPM
