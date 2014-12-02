#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/spec'

module Polisher::RPM
  describe Spec do
    describe "#files" do
      it "returns flattened files in all packages" do
        spec = described_class.new :pkg_files => {'foo' => ['file1'],
                                                  'doc' => ['docfile']}
        spec.files.should == %w(file1 docfile)
      end
    end
  end # describe Spec
end # module Polisher::RPM
