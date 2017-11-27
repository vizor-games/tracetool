require_relative build('version')

module Tracetool
  module Build
    module Version
      describe Bumper do
        let(:source) do
          <<-VERSION_RB.strip_indent
          module Tracetool
            # Version constant
            module Version
              VERSION = [1, 2, 3].freeze

              class << self
                # @return [String] version string
                def to_s
                  VERSION.join('.')
                end
              end
            end
          end
          VERSION_RB
        end

        context 'when major' do
          it 'updates major version and wipes minor and patch' do
            expect(IO)
              .to receive(:read).and_return(source)
            expect(IO)
              .to receive(:write).with('test.rb', source.gsub('[1, 2, 3]', '[2, 0, 0]'))
            Bumper.new('test.rb').bump(major: 1)
          end
        end

        context 'when minor' do
          it 'updates minor version and wipes patch' do
            expect(IO)
              .to receive(:read).and_return(source)
            expect(IO)
              .to receive(:write).with('test.rb', source.gsub('[1, 2, 3]', '[1, 3, 0]'))
            Bumper.new('test.rb').bump(minor: 1)
          end
        end

        context 'when patch' do
          it 'updates patch' do
            expect(IO)
              .to receive(:read).and_return(source)
            expect(IO)
              .to receive(:write).with('test.rb', source.gsub('[1, 2, 3]', '[1, 2, 4]'))
            Bumper.new('test.rb').bump(patch: 1)
          end
        end

        context 'when all set' do
          it 'increments minor and set other' do
            expect(IO)
              .to receive(:read).and_return(source)
            expect(IO)
              .to receive(:write).with('test.rb', source.gsub('[1, 2, 3]', '[2, 4, 5]'))
            Bumper.new('test.rb').bump(major: 1, minor: 4, patch: 5)
          end
        end
      end
    end
  end
end
