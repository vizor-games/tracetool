require_relative lib('tracetool/utils/env')

describe Tracetool::Env do
  describe '::which' do
    context 'when executable exists' do
      it 'returns executable name' do
        expect(Tracetool::Env.which('ruby')).to be_a(String)
      end
    end

    context 'when executable does not exist' do
      it 'returns nil' do
        expect(Tracetool::Env.which('mambo-jambo')).to be_nil
      end
    end
  end

  describe '::ensure_command' do
    context 'when executable does not exist' do
      it do
        expect { Tracetool::Env.ensure_command('mambo-jambo') }
          .to raise_error(ArgumentError)
      end
    end

    context 'when executable exists' do
      it do
        expect { Tracetool::Env.ensure_command('ruby') }.to_not raise_error
      end
    end
  end
end
