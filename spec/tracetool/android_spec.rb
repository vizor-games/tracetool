require_relative lib('tracetool/android')

describe Tracetool::Android::AndroidTraceScanner do
  let(:scanner) { Tracetool::Android }

  describe '#process' do
    context('when it not a trace') do
      it 'raises ArgumentError' do
        expect { scanner.scan('NOT A TRACE', {}) }
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
        expect(scanner.scan(trace, ctx)).to eq(trace)
      end
    end

    context('when it native trace') do
      context('when it logcat trace') do
        let(:trace) do
          <<-LOGCAT.strip_indent
          I/DEBUG   (   31): *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
          I/DEBUG   (   31): Build fingerprint: 'generic/google_sdk/generic/:2.2/FRF91/43546:eng/test-keys'
          I/DEBUG   (   31): pid: 351, tid: 351  >>> /data/local/ndk-tests/crasher <<<
          I/DEBUG   (   31): signal 11 (SIGSEGV), fault addr 0d9f00d8
          I/DEBUG   (   31):  r0 0000af88  r1 0000a008  r2 baadf00d  r3 0d9f00d8
          I/DEBUG   (   31):  r4 00000004  r5 0000a008  r6 0000af88  r7 00013c44
          I/DEBUG   (   31):  r8 00000000  r9 00000000  10 00000000  fp 00000000
          I/DEBUG   (   31):  ip 0000959c  sp be956cc8  lr 00008403  pc 0000841e  cpsr 60000030
          I/DEBUG   (   31):          #00  pc 0000841e  /data/local/ndk-tests/crasher
          I/DEBUG   (   31):          #01  pc 000083fe  /data/local/ndk-tests/crasher
          I/DEBUG   (   31):          #02  pc 000083f6  /data/local/ndk-tests/crasher
          I/DEBUG   (   31):          #03  pc 000191ac  /system/lib/libc.so
          I/DEBUG   (   31):          #04  pc 000083ea  /data/local/ndk-tests/crasher
          I/DEBUG   (   31):          #05  pc 00008458  /data/local/ndk-tests/crasher
          I/DEBUG   (   31):          #06  pc 0000d362  /system/lib/libc.so
          I/DEBUG   (   31):
          LOGCAT
        end
        it 'should process native trace' do
          exec = Tracetool::Pipe::Executor.new('cmd')
          allow(exec).to receive(:<<).and_return('native')
          allow(Tracetool::Pipe).to receive(:[]).and_return(exec)

          expect(scanner.scan(trace, symbols: '/tmp'))
            .to eq('native')
        end
      end

      context('when it striped trace') do
        let(:trace) do
          <<-TRACE.strip_indent
          backtrace:
              native: pc 00000000004321ec  libvizornative.so
              native: pc 000000000042db8d  libvizornative.so
              native: pc 0000000000c35865  base.odex
          TRACE
        end
        it 'should process native trace' do
          exec = Tracetool::Pipe::Executor.new('cmd')
          allow(exec).to receive(:<<).and_return('native')
          allow(Tracetool::Pipe).to receive(:[]).and_return(exec)

          expect(scanner.scan(trace, symbols: '/tmp'))
            .to eq('native')
        end
      end

      context('when it clean trace') do
        it 'should process native trace' do
          exec = Tracetool::Pipe::Executor.new('cmd')
          allow(exec).to receive(:<<).and_return('native')
          allow(Tracetool::Pipe).to receive(:[]).and_return(exec)

          expect(scanner.scan('<<<123456 foo.so ;>>>', symbols: '/tmp'))
            .to eq('native')
        end
      end
    end
  end
end
