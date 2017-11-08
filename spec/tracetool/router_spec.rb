require_relative '../../lib/tracetool/router'

describe Tracetool::AndroidNdkMatcher do
  describe '#match' do
    context 'when it logcat output with trace' do
      let (:matcher) { Tracetool::AndroidNdkMatcher.new }
      let (:trace) do
        # Example from https://developer.android.com/ndk/guides/ndk-stack.html
        <<-NDK.strip_indent
        I/DEBUG   (   31): *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
        I/DEBUG   (   31): Build fingerprint: 'generic/google_sdk/generic/:2.2/FRF91/43546:eng/test-keys'
        I/DEBUG   (   31): pid: 351, tid: 351  %gt;%gt;%gt; /data/local/ndk-tests/crasher <<<
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
        NDK
      end

      it 'matches' do
        expect(matcher.match(trace)).to be_truthy
      end
    end
  end
end

describe Tracetool::AndroidNdkPackedMatcher do
  describe '#match' do
    context 'when it packed trace' do
      let(:matcher) { Tracetool::AndroidNdkPackedMatcher.new }
      let(:trace) do
        '<<<10835662 libvizornative.so ;' \
            '10816006 libvizornative.so ;' \
            '4308016 libvizornative.so ;' \
            '2108 libsigchain.so _ZN3art23InvokeUserSignalHandlerEiP7siginfoPv 75;' \
            '2337826 libart.so _ZN3art12FaultManager11HandleFaultEiP7siginfoPv 181;' \
            '10931540 libvizornative.so ;' \
            '6756477 libvizornative.so ;' \
            '10658601 libvizornative.so ;' \
            '10474403 libvizornative.so ;' \
            '10487771 libvizornative.so ;' \
            '7914703 libvizornative.so ;' \
            '7914873 libvizornative.so ;' \
            '7914007 libvizornative.so ;' \
            '7911119 libvizornative.so ;' \
            '7904757 libvizornative.so ;' \
            '7916157 libvizornative.so ;' \
            '7911607 libvizornative.so ;' \
            '7904757 libvizornative.so ;' \
            '7919569 libvizornative.so ;' \
            '7590625 libvizornative.so ;' \
            '7628069 libvizornative.so ;' \
            '4315405 libvizornative.so Java_com_vizor_mobile_android_NativeApp_onUpdate 40;' \
            '62429345 libvizornative.so ;' \
            '>>>'
      end

      it 'should match' do
        expect(matcher.match(trace)).to be_truthy
      end
    end

    let(:matcher) { Tracetool::AndroidNdkPackedMatcher.new }
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
end

describe Tracetool::AndroidJavaMatcher do
  describe '#match' do
    context 'when example java trace' do
      let(:trace) do
        <<-JAVA.strip_indent
        java.lang.OutOfMemoryError: pthread_create (1040KB stack) failed: Try again
          at java.lang.Thread.nativeCreate(Native Method)
          at java.lang.Thread.start(Thread.java:1063)
          at java.util.concurrent.ThreadPoolExecutor.addWorker(ThreadPoolExecutor.java:920)
          at java.util.concurrent.ThreadPoolExecutor.ensurePrestart(ThreadPoolExecutor.java:1553)
          at java.util.concurrent.ScheduledThreadPoolExecutor.delayedExecute(ScheduledThreadPoolExecutor.java:306)
          at java.util.concurrent.ScheduledThreadPoolExecutor.schedule(ScheduledThreadPoolExecutor.java:503)
          at com.appsflyer.f.a(SourceFile:1170)
          at com.appsflyer.f.b(SourceFile:862)
          at com.appsflyer.m.a(SourceFile:17)
          at com.appsflyer.f$1.a(SourceFile:297)
          at com.appsflyer.t.onActivityResumed(SourceFile:140)
          at android.app.Application.dispatchActivityResumed(Application.java:232)
          at android.app.Activity.onResume(Activity.java:1299)
          at com.vizor.mobile.android.NativeAndroidActivity.onResume(SourceFile:126)
          at com.vizorapps.klondike.MainActivity.onResume(SourceFile:76)
          at android.app.Instrumentation.callActivityOnResume(Instrumentation.java:1255)
          at android.app.Activity.performResume(Activity.java:6495)
          at android.app.ActivityThread.performResumeActivity(ActivityThread.java:3510)
          at android.app.ActivityThread.handleResumeActivity(ActivityThread.java:3552)
          at android.app.ActivityThread$H.handleMessage(ActivityThread.java:1520)
          at android.os.Handler.dispatchMessage(Handler.java:102)
          at android.os.Looper.loop(Looper.java:145)
          at android.app.ActivityThread.main(ActivityThread.java:6134)
          at java.lang.reflect.Method.invoke(Native Method)
          at java.lang.reflect.Method.invoke(Method.java:372)
          at com.android.internal.os.ZygoteInit$MethodAndArgsCaller.run(ZygoteInit.java:1399)
          at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1194)
        JAVA
      end

      let(:matcher) { Tracetool::AndroidJavaMatcher.new }

      it 'should match java trace' do
        expect(matcher.match(trace)).to be_truthy
      end
    end
  end
end

describe Tracetool::Router do
  describe '#handle' do
    context 'string content' do
      let(:router) { Tracetool::Router.new({}, {/.*/ => :test}) }
      it 'should sanitize strings' do
        fixtures = {
            'foo\nbar' => "foo\nbar",
            'foo\tbar' => "foo\tbar"
        }

        fixtures.each do |original, sanitized|
          expect(router.handle(original)).to eq(sanitized)
        end
      end
    end

    context 'context should be passed' do
      let(:ctx) { OpenStruct.new(foo: 42) }
      let(:router) { Tracetool::Router.new(ctx, {/.*/ => :test }).on(:test, &->(_s, ctx) { ctx } ) }
      it { expect(router.handle('test')).to be(ctx) }
    end
  end
end

describe Tracetool::AndroidRouter do
  describe 'event handlers' do
    let(:router) { Tracetool::AndroidRouter.new }

    Tracetool::AndroidRouter::ROUTES.values.each do |method|
      it "responds to #{method}" do
        expect(router).to respond_to(method)
      end
    end
  end

  describe '#handle', fixture: :router do
    context 'when java trace' do
      let(:router) { strict_android_router.java { |_s, _ctx| 'java' } }
      it 'calls java event' do
        trace = <<-JAVA.strip_indent
          java.lang.OutOfMemoryError: pthread_create (1040KB stack) failed: Try again
            at java.lang.Thread.nativeCreate(Native Method)
            at java.lang.Thread.start(Thread.java:1063)
            at java.util.concurrent.ThreadPoolExecutor.addWorker(ThreadPoolExecutor.java:920)
            at java.util.concurrent.ThreadPoolExecutor.ensurePrestart(ThreadPoolExecutor.java:1553)
        JAVA

        expect(router.handle(trace)).to eq('java')
      end
    end

    context 'when ndk trace' do
      let(:router) { strict_android_router.ndk { |_s, _ctx| 'ndk' } }
      it 'calls ndk event' do
        trace = <<-NDK.strip_indent
        I/DEBUG   (   31): *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
        I/DEBUG   (   31): Build fingerprint: 'generic/google_sdk/generic/:2.2/FRF91/43546:eng/test-keys'
        I/DEBUG   (   31): pid: 351, tid: 351  %gt;%gt;%gt; /data/local/ndk-tests/crasher <<<
        I/DEBUG   (   31): signal 11 (SIGSEGV), fault addr 0d9f00d8
        I/DEBUG   (   31):  r0 0000af88  r1 0000a008  r2 baadf00d  r3 0d9f00d8
        I/DEBUG   (   31):  r4 00000004  r5 0000a008  r6 0000af88  r7 00013c44
        I/DEBUG   (   31):  r8 00000000  r9 00000000  10 00000000  fp 00000000
        I/DEBUG   (   31):  ip 0000959c  sp be956cc8  lr 00008403  pc 0000841e  cpsr 60000030
        I/DEBUG   (   31):          #00  pc 0000841e  /data/local/ndk-tests/crasher
        I/DEBUG   (   31):          #01  pc 000083fe  /data/local/ndk-tests/crasher
        I/DEBUG   (   31):          #02  pc 000083f6  /data/local/ndk-tests/crasher
        I/DEBUG   (   31):          #03  pc 000191ac  /system/lib/libc.so
        NDK

        expect(router.handle(trace)).to eq('ndk')
      end
    end

    context 'when packed ndk trace' do
      let(:router) { strict_android_router.packed_ndk { |_s, _ctx| 'packed-ndk' } }
      it 'calls packed_ndk_event' do
        trace = '<<<12345678 foo.so ;>>>'
        expect(router.handle(trace)).to eq('packed-ndk')
      end
    end
  end
end