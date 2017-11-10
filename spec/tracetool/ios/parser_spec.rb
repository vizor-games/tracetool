require_relative lib('tracetool/ios/parser')

describe Tracetool::IOS::IOSTraceParser do
  let(:trace) do
    <<-IOS.strip_indent
    0 FooModule some::cpp::namespace::CppClass::method(int, int, void*) (in FooModule) (CppClass.cpp:98)
    1 FooModule -[FooViewController touchesEnded:withEvent:] (in FooModule) (FooViewController.mm:314)
    2 UIKit 0X000000018559e56c
    IOS
  end

  let(:parser) { Tracetool::IOS::IOSTraceParser.new([]) }

  it 'extracts stack frame' do
    expect(parser.parse(trace).first[:frame]).to eq(0)
  end

  it 'extracts binary name' do
    expect(parser.parse(trace).first[:binary]).to eq('FooModule')
  end

  context 'when it cpp call' do
    let(:trace) do
      <<-IOS.strip_indent
      0 FooModule some::cpp::namespace::CppClass::method(int, int, void*) (in FooModule) (CppClass.cpp:98)
      IOS
    end

    it 'extracts call_description' do
      expect(parser.parse(trace).first[:call_description])
        .to eq('some::cpp::namespace::CppClass::method(int, int, void*) (in FooModule) (CppClass.cpp:98)')
    end

    it 'extracts method' do
      expect(parser.parse(trace).first[:call][:method])
        .to eq('some::cpp::namespace::CppClass::method(int, int, void*)')
    end

    it 'extracts module' do
      expect(parser.parse(trace).first[:call][:module]).to eq('FooModule')
    end

    it 'extracts file' do
      expect(parser.parse(trace).first[:call][:file]).to eq('CppClass.cpp')
    end

    it 'extracts file' do
      expect(parser.parse(trace).first[:call][:line]).to eq(98)
    end
  end

  context 'when it objective c call' do
    let(:trace) do
      <<-IOS.strip_indent
      1 FooModule -[FooViewController touchesEnded:withEvent:] (in FooModule) (FooViewController.mm:314)
      IOS
    end

    it 'extracts class' do
      expect(parser.parse(trace).first[:call][:class])
        .to eq('FooViewController')
    end

    it 'extracts method' do
      expect(parser.parse(trace).first[:call][:method])
        .to eq('touchesEnded:withEvent:')
    end

    it 'extracts module' do
      expect(parser.parse(trace).first[:call][:module])
        .to eq('FooModule')
    end

    it 'extracts file' do
      expect(parser.parse(trace).first[:call][:file])
        .to eq('FooViewController.mm')
    end

    it 'extracts line' do
      expect(parser.parse(trace).first[:call][:line]).to eq(314)
    end
  end

  context 'when it unknown call' do
    let(:trace) do
      <<-IOS.strip_indent
      2 UIKit 0X000000018559e56c
      IOS
    end

    it 'extracts address as call_description' do
      expect(parser.parse(trace).first[:call_description]).to eq('0X000000018559e56c')
    end
  end
end
