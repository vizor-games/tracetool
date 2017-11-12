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

    context 'when ndk-stack installed' do
      before(:all) do
        @tmp_dir = Dir.mktmpdir
        ndk_stack = File.join(@tmp_dir, 'ndk-stack')
        FileUtils.touch(ndk_stack)
        FileUtils.chmod('+x', ndk_stack)
      end

      it do
        expect { Tracetool::Env.ensure_ndk_stack }.to_not raise_error
      end

      after(:all) do
        FileUtils.remove_entry @tmp_dir
      end
    end

    context 'when ndk-stack not installed' do
      it do
        allow(ENV).to receive(:[]).and_return('')
        expect { Tracetool::Env.ensure_ndk_stack }.to raise_error(ArgumentError)
      end
    end

    context 'when atos installed' do
      before(:all) do
        @tmp_dir = Dir.mktmpdir
        ndk_stack = File.join(@tmp_dir, 'atos')
        FileUtils.touch(ndk_stack)
        FileUtils.chmod('+x', ndk_stack)
      end

      it do
        expect { Tracetool::Env.ensure_atos }.to_not raise_error
      end

      after(:all) do
        FileUtils.remove_entry @tmp_dir
      end
    end

    context 'when atos not installed' do
      it do
        allow(ENV).to receive(:[]).and_return('')
        expect { Tracetool::Env.ensure_atos }.to raise_error(ArgumentError)
      end
    end
  end
end
