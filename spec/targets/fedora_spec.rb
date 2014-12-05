# Polisher Fedora Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/targets/fedora'

module Polisher
  describe Fedora do
    describe "#gems_owned_by" do
      it "retrieves gems owned by the specified user"
    end

    describe "#versions_for" do
      it "dispatches to bodhi to retrieve / return versions" do
        Polisher::Bodhi.should_receive(:versions_for).with('rails').and_return(['1.0.0'])
        described_class.versions_for('rails').should == ['1.0.0']
      end

      it "should invoke callback" do
        Polisher::Bodhi.should_receive(:versions_for).with('rails')
                       .and_yield(:bodhi, 'rails', ['1.0.0'])
        cb = proc {}
        cb.should_receive(:call).with(:fedora, 'rails', ['1.0.0'])
        described_class.versions_for('rails', &cb)
      end
    end
  end # describe Fedora
end # module Polisher
