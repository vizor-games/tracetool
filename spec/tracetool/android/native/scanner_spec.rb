require_relative lib('tracetool/android/native/scanner')

describe Tracetool::Android::NativeTraceScanner do
  describe '::match' do
    let(:matcher) { Tracetool::Android::NativeTraceScanner }

    context 'when it packed trace' do
      it 'should not match empty string' do
        expect(matcher.match('')).to be_falsey
      end

      it 'should not match empty trace (<<<>>>)' do
        expect(matcher.match('<<<>>>')).to be_falsey
      end

      it 'should match single line trace' do
        expect(matcher.match('<<<12345678 foo.so ;>>>')).to be_truthy
      end

      it 'should match single line trace with symbol' do
        expect(matcher.match('<<<12345678 foo.so __bar 42;>>>')).to be_truthy
      end

      it 'should match multi line trace' do
        expect(matcher.match('<<<12345678 foo.so ;12345678 foo.so ;>>>')).to be_truthy
      end

      it 'should match multi line trace with symbol' do
        trace = '<<<12345678 foo.so __bar 42;12345678 foo.so __bar 42;>>>'
        expect(matcher.match(trace)).to be_truthy
      end

      it 'should match multi line trace combined' do
        trace = '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>'
        expect(matcher.match(trace)).to be_truthy
      end

      it 'should match sequential blocks' do
        trace = '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>' \
              '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>'
        expect(matcher.match(trace)).to be_truthy
      end
    end
    context 'when it system trace' do
      let(:trace) do
        # Example from https://developer.android.com/ndk/guides/ndk-stack.html
        <<-TRACE.strip_indent
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
        TRACE
      end

      it 'matches' do
        expect(matcher.match(trace)).to be_truthy
      end
    end
    context 'when it clean crash report' do
      let(:trace) do
        <<-TRACE.strip_indent
        *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
        Build fingerprint: 'generic/google_sdk/generic/:2.2/FRF91/43546:eng/test-keys'
        pid: 351, tid: 351  >>> /data/local/ndk-tests/crasher <<<
        signal 11 (SIGSEGV), fault addr 0d9f00d8
         r0 0000af88  r1 0000a008  r2 baadf00d  r3 0d9f00d8
         r4 00000004  r5 0000a008  r6 0000af88  r7 00013c44
         r8 00000000  r9 00000000  10 00000000  fp 00000000
         ip 0000959c  sp be956cc8  lr 00008403  pc 0000841e  cpsr 60000030
        backtrace:
            native: pc 00000000004321ec  libvizornative.so
            native: pc 000000000042db8d  libvizornative.so
            native: pc 0000000000c35865  base.odex
        TRACE
      end
      it 'should match' do
        expect(matcher.match(trace)).to be_truthy
      end
    end

    context 'when it striped crash' do
      let(:trace) do
        <<-TRACE.strip_indent
        backtrace:
            native: pc 00000000004321ec  libvizornative.so
            native: pc 000000000042db8d  libvizornative.so
            native: pc 0000000000c35865  base.odex
        TRACE
      end
      it 'should match' do
        expect(matcher.match(trace)).to be_truthy
      end
    end

    context 'when it crash with stack frames' do
      let(:trace) do
        <<-TRACE.strip_indent
        backtrace:
            #00 pc 00000000004321ec  libvizornative.so
            #00 pc 000000000042db8d  libvizornative.so
            #00 pc 0000000000c35865  base.odex
        TRACE
      end
      it 'should match' do
        expect(matcher.match(trace)).to be_truthy
      end
    end
  end
end
