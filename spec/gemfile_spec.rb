# Polisher Gemfile Specs
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/gemfile'

module Polisher
  describe Gemfile do
    describe "#initialize" do
      it "sets gemfile deps,dev_deps" do
        gemfile = Polisher::Gemfile.new :deps => ['rails'], :dev_deps => ['rake']
        gemfile.deps.should == ['rails']
        gemfile.dev_deps.should == ['rake']
      end

      it "sets default gemfile version,files" do
        gemfile = Polisher::Gemfile.new
        gemfile.version.should be_nil
        gemfile.file_paths.should == []
      end
    end
  end # describe Gemfile
end # module Polisher
