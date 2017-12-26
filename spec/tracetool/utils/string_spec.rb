require_relative lib('tracetool/utils/string')

module Tracetool
  module StringUtils
    describe String do
      describe 'longest_common_postfix' do
        context 'when strings has no common postfix' do
          it 'returns empty string' do
            expect('aaa'.longest_common_postfix('bbb')).to eq('')
          end
        end

        context 'when other string is a postfix of original string' do
          it 'returns other string' do
            expect('xyz-other'.longest_common_postfix('other')).to eq('other')
          end
        end

        context 'when original string is a postfix of other string' do
          it 'returns original string' do
            expect('original'.longest_common_postfix('xyz-original')).to eq('original')
          end
        end
      end
    end
  end
end
