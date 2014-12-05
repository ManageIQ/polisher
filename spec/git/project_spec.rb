#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/project'

module Polisher
  describe Git::Project do
    describe "#vendored" do
      context "repo not cloned" do
        it "clones repo" do
          git = described_class.new
          git.should_receive(:cloned?).and_return(false)
          git.should_receive(:clone)
          git.should_receive(:vendored_file_paths).and_return([]) # stub out
          git.vendored
        end
      end
    end
  end
end # module Polisher
