require_relative lib('tracetool/android/native')

module Tracetool
  module Android
    describe NativeTraceScanner do
      describe '::packed?' do
        context 'when it packed trace' do
          it 'should not match empty trace (<<<>>>)' do
            expect(NativeTraceScanner.packed?('<<<>>>')).to be_falsey
          end

          it 'should match single line trace' do
            expect(NativeTraceScanner.packed?('<<<12345678 foo.so ;>>>')).to be_truthy
          end

          it 'should match single line trace with symbol' do
            expect(NativeTraceScanner.packed?('<<<12345678 foo.so __bar 42;>>>')).to be_truthy
          end

          it 'should match multi line trace' do
            expect(NativeTraceScanner.packed?('<<<12345678 foo.so ;12345678 foo.so ;>>>')).to be_truthy
          end

          it 'should match multi line trace with symbol' do
            trace = '<<<12345678 foo.so __bar 42;12345678 foo.so __bar 42;>>>'
            expect(NativeTraceScanner.packed?(trace)).to be_truthy
          end

          it 'should match multi line trace combined' do
            trace = '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>'
            expect(NativeTraceScanner.packed?(trace)).to be_truthy
          end

          it 'should match sequential blocks' do
            trace = '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>' \
              '<<<12345678 foo.so ;12345678 foo.so __bar 42;>>>'
            expect(NativeTraceScanner.packed?(trace)).to be_truthy
          end

          it 'should match trace with signed address' do
            trace = '<<<12345678 foo.so ;-13080997 foo.so ;12345678 foo.so __bar 42;>>>'
            expect(NativeTraceScanner.packed?(trace)).to be_truthy
          end

          it do
            trace = '<<<305256 libc.so tgkill+12;294883 libc.so pthread_kill+34;121773 libc.so raise+10;>>>'
            expect(NativeTraceScanner.packed?(trace)).to be_truthy
          end

          it 'should match with negative pointers' do
            trace = '<<<-12345678 foo.so ;12345678 foo.so __bar 42;>>>'
            expect(NativeTraceScanner.packed?(trace)).to be_truthy
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
          it do
            expect(NativeTraceScanner.without_header?(trace)).to be_truthy
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
          it do
            expect(NativeTraceScanner.without_header?(trace)).to be_truthy
          end
        end

        context 'when in trace from google play console' do
          let(:trace) do
            <<-TRACE.strip_indent
            #00  pc 000000000004a868  /system/lib/libc.so (tgkill+12)
            #01  pc 0000000000047fe3  /system/lib/libc.so (pthread_kill+34)
            #02  pc 000000000001dbad  /system/lib/libc.so (raise+10)
            #03  pc 0000000000019321  /system/lib/libc.so (__libc_android_abort+34)
            #04  pc 0000000000017388  /system/lib/libc.so (abort+4)
            TRACE
          end

          it do
            expect(NativeTraceScanner.without_header?(trace)).to be_truthy
          end
        end
      end

      describe '::without_header?' do
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

          it do
            expect(NativeTraceScanner.with_header?(trace)).to be_truthy
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
            expect(NativeTraceScanner.with_header?(trace)).to be_truthy
          end
        end
      end

      describe '#process' do
        skip_ndk_stack = if Tracetool::Env.which('ndk-stack')
                           false
                         else
                           'No ndk-stack found'
                         end

        let(:trace) do
          <<-TRACE.strip_indent
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
        end

        it 'pipes stack trace through ndk-stack', skip: skip_ndk_stack do
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
            expect(NativeTraceScanner.new(trace).process(ctx)).to eq(expect)
          end
        end

        context 'when context has arch and symbols' do
          let(:exec) { double }
          before do
            expect(Tracetool::Pipe::Executor)
              .to receive(:new)
              .with('ndk-stack', %w[-sym /tmp/symbols/local/arch])
              .and_return(exec)
            allow(exec).to receive(:<<).and_return('native')
          end

          it do
            ctx = OpenStruct.new(symbols: '/tmp/symbols', arch: 'arch')
            expect(NativeTraceScanner.new(trace).process(ctx)).to eq('native')
          end
        end

        context 'when context has only symbols' do
          let(:exec) { double }
          before do
            @tmp_dir = Dir.mktmpdir
            FileUtils.mkdir_p(File.join(@tmp_dir, 'local/arch'))
            expect(Tracetool::Pipe::Executor)
              .to receive(:new)
              .with('ndk-stack', ['-sym', File.join(@tmp_dir, 'local/arch')])
              .and_return(exec)
            allow(exec).to receive(:<<).and_return('native')
          end

          it do
            ctx = OpenStruct.new(symbols: @tmp_dir)
            expect(NativeTraceScanner.new(trace).process(ctx)).to eq('native')
          end

          after do
            FileUtils.remove_entry @tmp_dir
          end
        end
      end
    end

    describe NativeTraceEnhancer do
      let(:enhancer) do
        Class.new { extend NativeTraceEnhancer }
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
          NativeTraceEnhancer::NATIVE_DUMP_HEADER
        end
        it 'adds dummy header' do
          expect(enhancer.add_header('')).to eq(dummy_header)
        end
      end
    end
  end
end
