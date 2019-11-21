require_relative lib('tracetool/utils/pipe')

describe Tracetool::Pipe do
  context 'simple cat' do
    let(:pipe) { Tracetool::Pipe['cat'] }
    it 'passes arguments to cmd STDIN and reads STDOUT' do
      expect(pipe << 'Hello').to eq('Hello')
    end
  end

  context 'with arguments' do
    let(:pipe) { Tracetool::Pipe['grep', '-e', 'test'] }
    it 'creates cmd with args' do
      expect(pipe.cmd).to match_array(%w[grep -e test])
    end

    it 'interprets arguments correctly' do
      expect(pipe << 'test').to eq('test')
      expect(pipe << "test\nrest\ntest").to eq("test\ntest")
    end

    it 'raises exception if exit was\'t successfull' do
      expect { pipe << 'rest' }.to raise_error(RuntimeError)
    end
  end
end
