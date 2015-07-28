# Polisher RPM Patch Specs
#
# Licensed under the MIT license
# Copyright (C) 2014 Red Hat, Inc.

require 'polisher/rpm/patch'

module Polisher::RPM
  describe Patch do
    let(:patch) { described_class.new }

    describe "#initialize" do
      it "initializes patch attributes" do
        patch.title   = 'title'
        patch.content = 'content'
      end
    end

    describe "#spec_line" do
      it "returns spec patch line" do
        patch.title = 'title'
        patch.spec_line(1).should == "Patch1: title"
      end
    end

    describe "::from" do
      it "returns patch for each file modified in diff" do
        diff = "diff -r file1.rb file2.rb\ncontents\ncontents\n" \
               "diff -r file2.rb file3.rb\nmore contents"
        result = described_class.from(diff)

        result.size.should == 2
        result[0].should be_an_instance_of(Patch)
        result[0].title.should == 'file1.rb'
        result[0].content.should == "contents\ncontents\n"
        result[1].should be_an_instance_of(Patch)
        result[1].title.should == 'file2.rb'
        result[1].content.should == "more contents"
      end

      it "skips 'Only In Lines'" do
        diff = "diff -r file1.rb file2.rb\ncontents\nOnly in foo.rb"
        result = described_class.from(diff)
        result[0].content.should == "contents\n"
      end
    end
  end # describe Patch
end # module Polisher::RPM
