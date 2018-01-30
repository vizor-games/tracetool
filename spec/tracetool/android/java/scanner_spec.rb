require_relative lib('tracetool/android/java')

module Tracetool
  module Android
    describe JavaTraceScanner do
      describe '#match' do
        let(:matcher) { JavaTraceScanner }
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
            JAVA
          end
          it 'should match java trace' do
            expect(matcher.match(trace)).to be_truthy
          end
        end

        context 'when trace contains frames tagged with "Unknown source"' do
          let(:trace) do
            <<-JAVA.strip_indent
            java.lang.OutOfMemoryError: pthread_create (1040KB stack) failed: Try again
              at java.lang.Thread.nativeCreate(Native Method)
              at java.lang.Thread.start(Thread.java:1063)
              at com.google.android.zzv.zza(Unknown Source)
              at com.google.android.internal.zzv.zzg(Unknown Source)
            JAVA
          end

          it 'should match java trace' do
            expect(matcher.match(trace)).to be_truthy
          end
        end

        context 'when trace contains only message line' do
          let(:trace) do
            <<-JAVA.strip_indent
            java.lang.SecurityException: META-INF/MANIFEST.MF has invalid digest for a.png in a.png
            JAVA
          end

          it 'should match java trace' do
            expect(matcher.match(trace)).to be_truthy
          end
        end
      end

      describe '#parser' do
        it 'creates JavaTraceParser' do
          expect(JavaTraceScanner.new("java.lang.OutOfMemoryError: Try again\n").parser([]))
            .to be_a(JavaTraceParser)
        end
      end
    end
  end
end
