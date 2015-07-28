#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/git/pkg'

module Polisher
  describe Git::Pkg do
    describe "#versions_for" do
      it "git fetches the package" do
        pkg = described_class.new
        described_class.should_receive(:new)
                       .with(:name => 'rails')
                       .and_return(pkg)
        described_class.fetch_tgt.each { |tgt| pkg.should_receive(:fetch).with(tgt) }
        described_class.versions_for 'rails'
      end

      it "returns version of the package" do
        spec = Polisher::RPM::Spec.new :version => '1.0.0'
        pkg  = described_class.new
        pkg.should_receive(:fetch) # stub out fetch
        described_class.should_receive(:new).and_return(pkg)
        pkg.should_receive(:spec).and_return(spec)

        described_class.versions_for('rails').should == ['1.0.0']
      end

      it "invokes callback with version of package" do
        spec = Polisher::RPM::Spec.new :version => '1.0.0'
        pkg  = described_class.new
        pkg.should_receive(:fetch) # stub out fetch
        described_class.should_receive(:new).and_return(pkg)
        pkg.should_receive(:spec).and_return(spec)

        cb = proc {}
        cb.should_receive(:call).with(:git, 'rails', ['1.0.0'])
        described_class.versions_for('rails', &cb)
      end
    end
  end # describe Git::Pkg
end # module Polisher
