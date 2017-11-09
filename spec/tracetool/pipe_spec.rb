require_relative lib('tracetool/pipe')

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
      expect(pipe << 'rest').to eq('')
      expect(pipe << "test\nrest\ntest").to eq("test\ntest")
    end
  end
end