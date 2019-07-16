require lib('tracetool/android/native')

module Tracetool
  module Android
    describe NativeTraceParser, helpers: :ndk do
      let(:files) do
        <<-FILES.strip_indent.split("\n")
        foo/foo.cpp
        foo/foo.h
        bar/bar.cpp
        bar/bar.h
        FILES
      end

      let(:parser) do
        NativeTraceParser.new(files)
      end

      context 'when input is empty' do
        it 'returns []' do
          expect(parser.parse('')).to eq([])
        end
      end

      context 'when single line crash' do
        let(:crash) do
          with_header <<-CRASH.strip_indent
            Stack frame #00  pc 0000841e  crasher.so : Routine zoo in zoo.c:13
          CRASH
        end

        it 'contains single entry' do
          expect(parser.parse(crash).length).to eq(1)
        end

        it 'extracts frame number' do
          expect(parser.parse(crash).first[:frame]).to be_truthy
          expect(parser.parse(crash).first[:frame]).to eq(0)
        end

        it 'extracts address' do
          expect(parser.parse(crash).first[:address]).to eq('pc 0000841e')
        end

        it 'extracts library name' do
          expect(parser.parse(crash).first[:lib]).to eq('crasher.so')
        end

        it 'extracts call description' do
          expect(parser.parse(crash).first[:call_description]).to eq('Routine zoo in zoo.c:13')
        end

        it 'parses call' do
          expect(parser.parse(crash).first[:call])
            .to eq(file: 'zoo.c', line: 13, method: 'zoo')
        end
      end

      context 'when lib name contains !, _, etc' do
        let(:crash) do
          with_header <<-CRASH.strip_indent
            Stack frame #00  pc 013de04c  /data/app/com.foo-E3kI_P7yHky-xrYxNaAJMQ==/split_config.arm64_v8a.apk!/lib/arm64-v8a/libapp.so: Routine Throwable::ctorThrowable(String*, Throwable*) at /build/native/src/Throwable.cpp:73
          CRASH
        end

        it 'extracts lib name' do
          puts crash
          expect(parser.parse(crash).first[:lib])
            .to eq('/data/app/com.foo-E3kI_P7yHky-xrYxNaAJMQ==/split_config.arm64_v8a.apk!/lib/arm64-v8a/libapp.so')
        end
      end

      context 'when call doesn\'t match' do
        let(:crash) do
          with_header <<-CRASH.strip_indent
           Stack frame #00  pc 0000841e  crasher.so
          CRASH
        end

        it 'has no call section' do
          expect(parser.parse(crash).first.key?(:call)).to be(false)
        end
      end

      context 'when path to lib contains base64 like string' do
        let(:crash) do
          <<-CRASH.strip_indent
          Stack frame #09  pc 00b2a6ee  /data/app/com.test-RCFoNTyJmrpi2PRV_uWa4Q==/lib/arm/test.so: Routine foo() at test.cpp:42
          CRASH
        end
        it do
          e = {
            address: 'pc 00b2a6ee',
            call: { method: 'foo()', file: 'test.cpp', line: 42 },
            call_description: 'Routine foo() at test.cpp:42',
            frame: 9,
            lib: '/data/app/com.test-RCFoNTyJmrpi2PRV_uWa4Q==/lib/arm/test.so',
            orig: crash.split("\n").first
          }
          expect(parser.parse(crash).first).to eq(e)
        end
      end

      context 'when line contains address shift at the end' do
        let(:crash) do
          <<-CRASH.strip_indent
          Stack frame #05  pc 001faed4  /system/vendor/lib/egl/libGLESv2_adreno.so _ZN10A5xContext20WriteTexSamplersRegsEPjii 595
          CRASH
        end

        it do
          e = {
            address: 'pc 001faed4',
            call: { method: '_ZN10A5xContext20WriteTexSamplersRegsEPjii' },
            call_description: '_ZN10A5xContext20WriteTexSamplersRegsEPjii 595',
            frame: 5,
            lib: '/system/vendor/lib/egl/libGLESv2_adreno.so',
            orig: crash.chomp
          }

          expect(parser.parse(crash).first).to eq(e)
        end
      end
    end
  end
end
