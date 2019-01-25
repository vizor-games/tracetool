require_relative lib('tracetool/android/java')

describe Tracetool::Android::JavaTraceParser do
  context 'when it java trace' do
    let(:parser) { Tracetool::Android::JavaTraceParser.new([]) }
    let(:trace) do
      <<-JAVA.strip_indent
      java.lang.OutOfMemoryError: pthread_create (1040KB stack) failed: Try again
        at java.lang.Thread.nativeCreate(Native Method)
        at java.lang.Thread.start(Thread.java:1063)
        at java.util.concurrent.ThreadPoolExecutor.addWorker(ThreadPoolExecutor.java:920)
      Caused by: android.os.DeadObjectException
        at android.os.BinderProxy.transactNative(Native Method)
        at android.os.BinderProxy.transact(Binder.java:503)
        ... 234 more
      JAVA
    end

    it 'extracts error and message' do
      expect(parser.parse(trace).first[:message])
        .to eq('pthread_create (1040KB stack) failed: Try again')
      expect(parser.parse(trace).first[:error])
        .to eq('java.lang.OutOfMemoryError')
    end

    context 'when it has call description' do
      it 'extracts call description' do
        expect(parser.parse(trace)[2][:call_description])
          .to eq('java.lang.Thread.start(Thread.java:1063)')
      end
    end

    context 'when has valid call description' do
      it 'extracts class' do
        expect(parser.parse(trace)[2][:call][:class]).to eq('java.lang.Thread')
      end

      it 'extracts method' do
        expect(parser.parse(trace)[1][:call][:method]).to eq('nativeCreate')
      end

      it 'extracts file and line' do
        expect(parser.parse(trace)[2][:call][:file]).to eq('Thread.java')
        expect(parser.parse(trace)[2][:call][:line]).to eq(1063)
      end

      context 'when no file and line' do
        it 'extracts location' do
          expect(parser.parse(trace)[1][:call][:location]).to eq('Native Method')
        end
      end
    end
  end
end
