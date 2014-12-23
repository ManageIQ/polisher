#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/targets/koji'
require 'awesome_spawn'

module Polisher
  describe Koji do
    describe "#build" do
      it "runs build_cmd" do
        result = AwesomeSpawn::CommandResult.new "", "", "", 0
        expected = "#{described_class.build_cmd} build  #{described_class.build_tgt} srpm"
        AwesomeSpawn.should_receive(:run).with(expected).and_return(result)
        described_class.should_receive(:require_cmd!)
                       .with(described_class.build_cmd).and_return(true)
        described_class.build :srpm => 'srpm'
      end

      it "runs scratch build" do
        described_class.should_receive(:require_cmd!)
                       .with(described_class.build_cmd).and_return(true)
        result = AwesomeSpawn::CommandResult.new "", "", "", 0
        expected = "#{described_class.build_cmd} build --scratch f20 srpm"
        AwesomeSpawn.should_receive(:run).with(expected).and_return(result)
        described_class.build :target => 'f20', :srpm => 'srpm', :scratch => true
      end

      it "parses & returns url from build output" do
        described_class.should_receive(:require_cmd!).and_return(true)
        result = AwesomeSpawn::CommandResult.new "", "output", "", 0
        AwesomeSpawn.should_receive(:run).and_return(result)
        described_class.should_receive(:parse_url).with('output').and_return('url')
        described_class.build.should == 'url'
      end

      describe "non-zero build exit status" do
        it "raises runtime error with build url" do
          described_class.should_receive(:require_cmd!).and_return(true)
          result = AwesomeSpawn::CommandResult.new "", "", "", 1
          AwesomeSpawn.should_receive(:run).and_return(result)
          described_class.should_receive(:parse_url).and_return('url')
          lambda { described_class.build }.should raise_error(RuntimeError, 'url')
        end
      end
    end
  end # describe Koji
end # module Polisher
