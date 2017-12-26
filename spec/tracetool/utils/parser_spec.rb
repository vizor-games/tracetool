require_relative lib('tracetool/utils/parser')

describe Tracetool::BaseTraceParser do
  let(:entry_regexp) { /^A (?<lib>[a-z\._]+) (?<call_description>.+)$/ }
  let(:call_regexp) { /(?<method>[a-z]+) (?<file>.+):(?<line>\d+)$/ }

  describe '#parse' do
    let(:parser) do
      Tracetool::BaseTraceParser.new(entry_regexp, call_regexp, [])
    end

    it 'extracts named groups for each line' do
      expect(parser.parse('A test.foo call').first[:lib]).to eq('test.foo')
      expect(parser.parse('A test.foo call').first[:call_description]).to eq('call')
    end

    context 'when call_description matches call_regexp' do
      let(:trace) { 'A test.foo method file:10' }
      it 'extracts named groups from call_description into :call' do
        %i[method file line].zip(%w[method file 10]).each do |group, val|
          expect(parser.parse(trace).first[:call][group]).to eq(val)
        end
      end
    end

    context 'when trace has many lines' do
      let(:trace) do
        <<-TRACE.strip_indent
        A match.so something
        A match.so something
        B dont_match.so something
        B dont_match.so something
        A match.so something
        TRACE
      end
      it 'returns all matched entries' do
        expect(parser.parse(trace).length).to eq(3)
      end
    end

    context 'when has file list' do
      let(:files) { %w[com/foo/var.cpp com/bar/jar.cpp com/far/jar.cpp com/test1/foo/jar.cpp com/test2/foo/jar.cpp] }

      let(:parser) do
        Tracetool::BaseTraceParser.new(entry_regexp, call_regexp, files)
      end

      it 'resolves file group as file' do
        expect(parser.parse('A foo.so method var.cpp:10').first[:call][:file])
          .to eq('com/foo/var.cpp')
      end

      context 'when has ambiguous file name' do
        it 'returns all matching files' do
          expect(parser.parse('A foo.so method jar.cpp:10').first[:call][:file])
            .to match_array(%w[com/bar/jar.cpp com/far/jar.cpp com/test1/foo/jar.cpp com/test2/foo/jar.cpp])
        end
      end

      context 'when has exact filename among other matching' do
        it 'returns correct path' do
          expect(parser.parse('A foo.so method bar/jar.cpp:10').first[:call][:file])
            .to eq('com/bar/jar.cpp')
        end
      end

      context 'when has multiple files with same path postfix' do
        it 'returns all matching files' do
          expect(parser.parse('A foo.so method foo/jar.cpp:10').first[:call][:file])
            .to match_array(%w[com/test1/foo/jar.cpp com/test2/foo/jar.cpp])
        end
      end
    end

    context 'when has convert_numbers flag' do
      let(:parser) do
        Tracetool::BaseTraceParser.new(entry_regexp, call_regexp, [], true)
      end

      it 'converts \d+ groups to integers' do
        expect(parser.parse('A foo.so method file:10').first[:call][:line]).to eq(10)
      end
    end
  end
end
