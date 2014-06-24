require 'polisher/component'

module Polisher
  describe Component do
    describe ".verify" do
      it "executes block for no missing gems" do
        silence_stream(STDERR) do
          described_class.verify("Z", "rubygems", "rspec") do
            module ::Polisher
              class Z
                def self.yielded_block_executed
                  true
                end
              end
            end
          end
        end

        expect(Polisher::Z.yielded_block_executed).to be_true
      end

      describe "missing" do
        subject do
          silence_stream(STDERR) do
            described_class.verify(@test_class, "missing_gem") {}
          end
        end

        it "A" do
          @test_class = "A"
          subject
          expect(Polisher::A).to eql Polisher::Component::Missing
          expect { Polisher::A.new }.to raise_error
        end

        it "A::B" do
          @test_class = "A::B"
          subject
          expect(Polisher::A).to eql Polisher::Component::Missing
          expect(Polisher::A::B).to eql Polisher::Component::Missing
        end

        it "A::B::C" do
          @test_class = "A::B::C"
          subject
          expect(Polisher::A).to eql Polisher::Component::Missing
          expect(Polisher::A::B).to eql Polisher::Component::Missing
          expect(Polisher::A::B::C).to eql Polisher::Component::Missing
        end
      end
    end
  end
end
