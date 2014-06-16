# Polisher Yum Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/yum'

module Polisher
  describe Yum do
    describe "#versions_for" do
      before(:each) do
      end

      it "uses yum to retreive versions" do
        described_class.should_receive(:require_cmd!)
                       .with('/usr/bin/yum').and_return(true)
        expected = "/usr/bin/yum info rubygem-rails"
        result = AwesomeSpawn::CommandResult.new expected, "", "", 0
        AwesomeSpawn.should_receive(:run).with(expected).and_return(result)
        described_class.version_for "rails"
      end

      it "returns versions" do
        described_class.should_receive(:require_cmd!).and_return(true)
        result = AwesomeSpawn::CommandResult.new "", "Version: 1.0.0", "", 0
        AwesomeSpawn.should_receive(:run).and_return(result)
        described_class.version_for("rails") == '1.0.0'
      end

      it "invokes block with versions" do
        described_class.should_receive(:require_cmd!).and_return(true)

        cb = proc {}
        cb.should_receive(:call).with(:yum, 'rails', ['1.0.0'])

        result = AwesomeSpawn::CommandResult.new "", "Version: 1.0.0", "", 0
        AwesomeSpawn.should_receive(:run).and_return(result)
        described_class.version_for("rails", &cb)
      end
    end
  end # describe Koji
end # module Polisher
