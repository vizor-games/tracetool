require 'stringio'
require_relative lib('tracetool/utils/cli')

describe Tracetool::ParseArgs do
  let(:cli) { Tracetool::ParseArgs }
  describe '::parse' do
    context 'when missing platform' do
      it do
        io = StringIO.new
        expect { cli.parse(%w[--arch arm64], io) }
          .to raise_error(OptionParser::MissingArgument)
      end
    end

    context 'when missing arch' do
      it do
        io = StringIO.new
        expect { cli.parse(%w[--platform android], io) }
          .to raise_error(OptionParser::MissingArgument)
      end
    end

    context 'when wrong platform' do
      it do
        io = StringIO.new
        expect { cli.parse(%w[--platform amazon --arch], io) }
          .to raise_error(OptionParser::InvalidArgument)
      end
    end

    context 'when --help' do
      it 'prints help and exists' do
        io = StringIO.new
        expect { cli.parse(%w[--help], io) }
          .to exit(0)
      end
    end

    context 'when --version' do
      it 'prints version and exists' do
        io = StringIO.new
        expect { cli.parse(%w[--version], io) }
          .to exit(0)
      end
    end

    context 'when --symbols missing' do
      it 'contains use current working dir' do
        expect(cli.parse(%w[--platform android --arch x86]).sym_dir).to eq(Dir.pwd)
      end
    end

    context 'when has --symbols argument' do
      it 'contains argument value' do
        expect(cli.parse(%w[--platform android --arch x86 --symbols x]).sym_dir)
          .to eq('x')
      end
    end

    context 'ios' do
      context 'when address missing' do
        context 'when module missing' do
          it do
            io = StringIO.new
            expect { cli.parse(%w[--platform ios --address 0x0 --arch arm64], io) }
              .to raise_error(OptionParser::MissingArgument)
          end
        end

        it do
          io = StringIO.new
          expect { cli.parse(%w[--platform ios --module Foo --arch arm64], io) }
            .to raise_error(OptionParser::MissingArgument)
        end
      end
    end
  end
end
