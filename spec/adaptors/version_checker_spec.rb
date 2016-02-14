# Polisher Version Checker Spec
#
# Licensed under the MIT license
# Copyright (C) 2013-2014 Red Hat, Inc.

require 'polisher/adaptors/version_checker'
require 'polisher/targets/fedora'
require 'polisher/targets/koji'
require 'polisher/targets/yum'
require 'polisher/targets/bodhi'
require 'polisher/targets/errata'

require 'polisher/gem'
require 'polisher/git'

module Polisher
  describe VersionChecker do
    before(:each) do
      @check_list = described_class.instance_variable_get(:@check_list)
    end

    after(:each) do
      described_class.instance_variable_set(:@check_list, @check_list)
    end

    describe "#check" do
      it "adds target to check to list" do
        described_class.should_check?(:foo).should be_false
        described_class.check :foo
        described_class.should_check?(:foo).should be_true
      end
    end

    describe "#should_check?" do
      context "target is on check list" do
        it "returns true" do
          described_class.check :foo
          described_class.should_check?(:foo).should be_true
        end
      end

      context "target is not on check list" do
        it "returns false" do
          described_class.should_check?(:foo).should be_false
        end
      end
    end

    describe "#versions_for" do
      context "should check gem target" do
        it "checks gem target" do
          described_class.should_receive(:should_check?)
                         .with(:gem).and_return(true)

          described_class.should_receive(:should_check?)
                         .at_least(:once).and_return(false)

          bl = proc {}
          Polisher::Gem.should_receive(:local_versions_for)
                       .with('rails', &bl).and_return(['1.0.0'])
          described_class.versions_for('rails', &bl)[:gem].should == ['1.0.0']
        end
      end

      context "should check fedora target" do
        it "checks fedora target" do
          described_class.should_receive(:should_check?)
                         .with(:fedora).and_return(true)
          described_class.should_receive(:should_check?)
                         .at_least(:once).and_return(false)

          bl = proc {}
          Fedora.should_receive(:versions_for)
                .with('rails', &bl).and_return(['1.0.0'])
          described_class.versions_for('rails', &bl)[:fedora].should == ['1.0.0']
        end

        context "error retrieving versions from fedora" do
          it "yields 'unknown' for fedora target" do
            described_class.should_receive(:should_check?)
                           .with(:fedora).and_return(true)
            described_class.should_receive(:should_check?)
                           .at_least(:once).and_return(false)

            Fedora.should_receive(:versions_for)
                  .with('rails').and_raise(RuntimeError)
            described_class.versions_for('rails')[:fedora].should == [:unknown]
          end
        end
      end

      context "should check koji target" do
        it "checks koji target" do
          described_class.should_receive(:should_check?)
                         .with(:koji).and_return(true)
          described_class.should_receive(:should_check?)
                         .at_least(:once).and_return(false)

          bl = proc {}
          Koji.should_receive(:versions_for)
              .with('rails', &bl).and_return(['1.0.0'])
          described_class.versions_for('rails', &bl)[:koji].should == ['1.0.0']
        end

        context "error retrieving versions from koji" do
          it "yield 'unknown' for koji version" do
            described_class.should_receive(:should_check?)
                           .with(:koji).and_return(true)
            described_class.should_receive(:should_check?)
                           .at_least(:once).and_return(false)

            Koji.should_receive(:versions_for)
                .with('rails').and_raise(RuntimeError)
            described_class.versions_for('rails')[:koji].should == [:unknown]
          end
        end
      end

      context "should check git target" do
        it "checks git target" do
          described_class.should_receive(:should_check?)
                         .with(:git).and_return(true)
          described_class.should_receive(:should_check?)
                         .at_least(:once).and_return(false)

          bl = proc {}
          Git::Pkg.should_receive(:versions_for)
                   .with('rails', &bl).and_return(['1.0.0'])
          described_class.versions_for('rails', &bl)[:git].should == ['1.0.0']
        end

        context "error retrieving versions from git" do
          it "yield 'unknown' for git version" do
            described_class.should_receive(:should_check?)
                           .with(:git).and_return(true)
            described_class.should_receive(:should_check?)
                           .at_least(:once).and_return(false)

            Git::Pkg.should_receive(:versions_for)
                    .with('rails').and_raise(RuntimeError)
            described_class.versions_for('rails')[:git].should == [:unknown]
          end
        end
      end

      context "should check yum target" do
        it "checks yum target" do
          described_class.should_receive(:should_check?)
                         .with(:yum).and_return(true)
          described_class.should_receive(:should_check?)
                         .at_least(:once).and_return(false)

          bl = proc {}
          Yum.should_receive(:version_for)
             .with('rails', &bl).and_return('1.0.0')
          described_class.versions_for('rails', &bl)[:yum].should == ['1.0.0']
        end

        context "error retrieving versions from yum" do
          it "yield 'unknown' for yum version" do
            described_class.should_receive(:should_check?)
                           .with(:yum).and_return(true)
            described_class.should_receive(:should_check?)
                           .at_least(:once).and_return(false)

            Yum.should_receive(:version_for)
               .with('rails').and_raise(RuntimeError)
            described_class.versions_for('rails')[:yum].should == [:unknown]
          end
        end
      end

      context "should check bodhi target" do
        it "checks bodhi target" do
          described_class.should_receive(:should_check?)
                         .with(:bodhi).and_return(true)
          described_class.should_receive(:should_check?)
                         .at_least(:once).and_return(false)

          bl = proc {}
          Bodhi.should_receive(:versions_for)
               .with('rails', &bl).and_return(['1.0.0'])
          described_class.versions_for('rails', &bl)[:bodhi].should == ['1.0.0']
        end

        context "error retrieving versions from bodhi" do
          it "yield 'unknown' for bodhi version" do
            described_class.should_receive(:should_check?)
                           .with(:bodhi).and_return(true)
            described_class.should_receive(:should_check?)
                           .at_least(:once).and_return(false)

            Bodhi.should_receive(:versions_for)
                 .with('rails').and_raise(RuntimeError)
            described_class.versions_for('rails')[:bodhi].should == [:unknown]
          end
        end
      end

      context "should check errata target" do
        it "checks errata target" do
          described_class.should_receive(:should_check?)
                         .with(:errata).and_return(true)
          described_class.should_receive(:should_check?)
                         .at_least(:once).and_return(false)

          bl = proc {}
          Errata.should_receive(:versions_for)
                .with('rails', &bl).and_return(['1.0.0'])
          described_class.versions_for('rails', &bl)[:errata].should == ['1.0.0']
        end

        context "error retrieving versions from errata" do
          it "yield 'unknown' for errata version" do
            described_class.should_receive(:should_check?)
                           .with(:errata).and_return(true)
            described_class.should_receive(:should_check?)
                           .at_least(:once).and_return(false)

            Errata.should_receive(:versions_for)
                  .with('rails').and_raise(RuntimeError)
            described_class.versions_for('rails')[:errata].should == [:unknown]
          end
        end
      end

      it "returns all versions retrieved" do
        described_class.should_receive(:should_check?)
                       .at_least(:once).and_return(true)
        Polisher::Gem.should_receive(:local_versions_for).with('rails').and_return(['1.0.0'])
        Fedora.should_receive(:versions_for).with('rails').and_return(['2.0.0'])
        Koji.should_receive(:versions_for).with('rails').and_return(['3.0.0'])
        Git::Pkg.should_receive(:versions_for).with('rails').and_return(['4.0.0'])
        Yum.should_receive(:version_for).with('rails').and_raise(RuntimeError)
        Bodhi.should_receive(:versions_for).with('rails').and_return(['1.1.1'])
        Errata.should_receive(:versions_for).with('rails').and_return(['2.3.4'])

        expected = {:gem    => ['1.0.0'],
                    :fedora => ['2.0.0'],
                    :koji   => ['3.0.0'],
                    :git    => ['4.0.0'],
                    :yum    => [:unknown],
                    :bodhi  => ['1.1.1'],
                    :errata => ['2.3.4']}
        described_class.versions_for('rails').should == expected
      end
    end

    describe "version for" do
      it "retrieves most relevant version of package in configured targets" do
        versions = {:koji => ['1.0', '2.0', '1.0'],
                    :git  => ['3.0', '3.0'],
                    :yum  => ['2.0', '1.1', '2.0']}
        described_class.should_receive(:versions_for).and_return(versions)

        expected = {:koji => '1.0',
                    :git  => '3.0',
                    :yum  => '2.0'}
        described_class.version_for('rails').should == expected
      end
    end

    describe "#version_of" do
      it "retrieves most relevant version of package in all targets" do
        versions = {:koji   => '2.2',
                    :bodhi  => '2.2',
                    :errata => '4.4'}
        described_class.should_receive(:version_for).and_return(versions)
        described_class.version_of('rails').should == '2.2'
      end
    end
  end # describe VersionChecker
end # module Polisher
