require_relative lib('tracetool/android/native/scanner')

describe Tracetool::Android::NativeTraceScanner do
  let(:scanner) { Tracetool::Android::NativeTraceScanner }

  describe '::packed?' do
    context 'when it packed trace' do
      it 'should not match empty trace (<<<>>>)' do
        expect(scanner.packed?('<<<>>>')).to be_falsey
      end

      it 'should match single line trace' do
        expect(scanner.packed?('<<<12345678 foo.so ;>>>')).to be_truthy
      end

      it 'should match single line trace with symbol' do
        expect(scanner.packed?('<<<12345678 foo.so __bar 42;>>>')).to be_truthy
      end

      it 'should match multi line trace' do
        expect(scanner.packed?('<<<12345678 foo.so ;12345678 foo.so ;>>>')).to be_truthy
      end

      it 'should match multi line trace with symbol' do
        trace = '<<<12345678 foo.so __bar 42;12345678 foo.so __bar 42;>>>'
        expect(scanner.packed?(trace)).to be_truthy
      end

      it 'should match multi line trace combined' do
        trace = '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>'
        expect(scanner.packed?(trace)).to be_truthy
      end

      it 'should match sequential blocks' do
        trace = '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>' \
              '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>'
        expect(scanner.packed?(trace)).to be_truthy
      end
    end
  end

  describe '::without_header?' do
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
        expect(scanner.without_header?(trace)).to be_truthy
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
        expect(scanner.without_header?(trace)).to be_truthy
      end
    end
  end

  describe '::with_header?' do
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

      it 'should match' do
        expect(scanner.with_header?(trace)).to be_truthy
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
        expect(scanner.with_header?(trace)).to be_truthy
      end
    end
  end

  describe '#process' do
    it 'pipes stack trace through ndk-stack' do
      original =  <<-TRACE.strip_indent
      *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
      Build fingerprint: UNKNOWN
      pid: 0, tid: 0
      signal 0 (UNKNOWN)
      backtrace:
               #00  pc 0000841e  /data/local/ndk-tests/crasher
               #01  pc 000083fe  /data/local/ndk-tests/crasher
               #02  pc 000083f6  /data/local/ndk-tests/crasher
               #03  pc 000191ac  /system/lib/libc.so
               #04  pc 000083ea  /data/local/ndk-tests/crasher
               #05  pc 00008458  /data/local/ndk-tests/crasher
               #06  pc 0000d362  /system/lib/libc.so
      TRACE

      expect = <<-TRACE.strip_indent.chomp
      ********** Crash dump: **********
      Build fingerprint: UNKNOWN
      pid: 0, tid: 0
      signal 0 (UNKNOWN)
      Stack frame #00  pc 0000841e  /data/local/ndk-tests/crasher
      Stack frame #01  pc 000083fe  /data/local/ndk-tests/crasher
      Stack frame #02  pc 000083f6  /data/local/ndk-tests/crasher
      Stack frame #03  pc 000191ac  /system/lib/libc.so
      Stack frame #04  pc 000083ea  /data/local/ndk-tests/crasher
      Stack frame #05  pc 00008458  /data/local/ndk-tests/crasher
      Stack frame #06  pc 0000d362  /system/lib/libc.so
      TRACE

      Dir.mktmpdir do |dir|
        ctx = OpenStruct.new(symbols: dir)
        expect(scanner.new(original).process(ctx)).to eq(expect)
      end
    end
  end
end

describe Tracetool::Android::NativeTraceEnhancer do
  let(:enhancer) do
    Class.new { extend Tracetool::Android::NativeTraceEnhancer }
  end
  describe '#unpack' do
    it 'should convert packed trace to ndk trace' do
      unpacked = <<-NDK.strip_indent.chomp
    *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
    Build fingerprint: UNKNOWN
    pid: 0, tid: 0
    signal 0 (UNKNOWN)
    backtrace:
        #00  pc 000004d2  lib.so
      NDK
      expect(enhancer.unpack('<<<1234 lib.so ;>>>')).to eq(unpacked)
    end

    it 'should keep symbol and offset' do
      original = '<<<1234 lib.so _foo 42;>>>'
      unpacked = <<-NDK.strip_indent.chomp
      *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
      Build fingerprint: UNKNOWN
      pid: 0, tid: 0
      signal 0 (UNKNOWN)
      backtrace:
          #00  pc 000004d2  lib.so _foo 42
      NDK
      expect(enhancer.unpack(original)).to eq(unpacked)
    end

    it 'should convert multiline traces correctly' do
      original = '<<<1234 lib.so ;1234 lib.so ;1234 lib.so ;12345678 lib.so _foo 42;1234 lib.so ;>>>'
      unpacked = <<-NDK.strip_indent.chomp
      *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
      Build fingerprint: UNKNOWN
      pid: 0, tid: 0
      signal 0 (UNKNOWN)
      backtrace:
          #00  pc 000004d2  lib.so
          #01  pc 000004d2  lib.so
          #02  pc 000004d2  lib.so
          #03  pc 00bc614e  lib.so _foo 42
          #04  pc 000004d2  lib.so
      NDK
      expect(enhancer.unpack(original)).to eq(unpacked)
    end
  end

  describe '#add_header' do
    let(:dummy_header) do
      Tracetool::Android::NativeTraceEnhancer::NATIVE_DUMP_HEADER
    end
    it 'adds dummy header' do
      expect(enhancer.add_header('')).to eq(dummy_header)
    end
  end
end
