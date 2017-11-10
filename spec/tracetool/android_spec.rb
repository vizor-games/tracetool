require_relative lib('tracetool/android')

describe Tracetool::Android::AndroidTraceScanner do
  let(:scanner) { Tracetool::Android::AndroidTraceScanner.new }

  describe '#process' do
    context('when it not a trace') do
      it 'raises ArgumentError' do
        expect { scanner.process('NOT A TRACE', {}) }
          .to raise_error(ArgumentError)
      end
    end

    context('when it java trace') do
      let(:trace) do
        <<-JAVA.strip_indent
        java.lang.OutOfMemoryError: pthread_create (1040KB stack) failed: Try again
          at java.lang.Thread.nativeCreate(Native Method)
          at java.lang.Thread.start(Thread.java:1063)
          at java.util.concurrent.ThreadPoolExecutor.addWorker(ThreadPoolExecutor.java:920)
          at java.util.concurrent.ThreadPoolExecutor.ensurePrestart(ThreadPoolExecutor.java:1553)
        JAVA
      end

      let(:ctx) { OpenStruct.new }
      it 'should unpack java' do
        expect(scanner.process(trace, ctx)).to eq(trace)
      end
    end

    context('when it native trace') do
      context('when it logcat trace') do
        it 'should process native trace'
      end

      context('when it striped trace') do
        it 'should process native trace'
      end

      context('when it clean trace') do
        it 'should process native trace'
      end
    end
  end
end
