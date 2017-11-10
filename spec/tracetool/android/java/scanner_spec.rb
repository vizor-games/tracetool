require_relative lib('tracetool/android/java/scanner')

describe Tracetool::Android::JavaTraceScanner do
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

      let(:matcher) { Tracetool::Android::JavaTraceScanner }

      it 'should match java trace' do
        expect(matcher.match(trace)).to be_truthy
      end
    end
  end
end
