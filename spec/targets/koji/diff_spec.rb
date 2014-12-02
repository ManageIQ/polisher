#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/targets/koji'

module Polisher
  describe Koji do
    describe "#diff" do
      it "includes updated, added, deleted, unchanged rpms" do
        VCR.use_cassette('koji_diff_f19ruby_f21ruby') do
          results = Polisher::Koji.diff("f19-ruby", "f21-ruby")

          # updated
          results["rubygem-sqlite3"]["f19-ruby"].should == "1.3.5"
          results["rubygem-sqlite3"]["f21-ruby"].should == "1.3.8"

          # added
          results["rubygem-bcrypt"]["f19-ruby"].should be_nil
          results["rubygem-bcrypt"]["f21-ruby"].should == "3.1.7"

          # deleted
          results["rubygem-snmp"]["f19-ruby"].should == "1.1.0"
          results["rubygem-snmp"]["f21-ruby"].should be_nil

          # unchanged
          results["rubygem-RedCloth"]["f19-ruby"].should == "4.2.9"
          results["rubygem-RedCloth"]["f21-ruby"].should == "4.2.9"

          # f19 has 1.3.4 and 1.3.5
          results["rubygem-sinatra"]["f19-ruby"].should == "1.3.5"
        end
      end
    end
  end # describe Koji
end # module Polisher
