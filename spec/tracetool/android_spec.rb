require_relative lib('tracetool/android')
describe Tracetool::Android::NdkPackedTraceConverter do
  let(:p) { Tracetool::Android::NdkPackedTraceConverter.new }
  it 'should convert packed trace to ndk trace' do
    unpacked = <<-NDK.strip_indent.chomp
    *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
    Build fingerprint: UNKNOWN
    pid: 0, tid: 0
    signal 0 (UNKNOWN)
    backtrace:
        #00  pc 000004d2  lib.so
    NDK
    expect(p.process('<<<1234 lib.so ;>>>', nil)).to eq(unpacked)
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
    expect(p.process(original, nil)).to eq(unpacked)
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
    expect(p.process(original, nil)).to eq(unpacked)
  end
end

describe Tracetool::Android::NdkStackLauncher do
  let(:ndk_stack) { Tracetool::Android::NdkStackLauncher.new }
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
      expect(ndk_stack.process(original, OpenStruct.new(symbols: dir))).to eq(expect)
    end
  end
end