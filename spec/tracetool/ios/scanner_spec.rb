require_relative lib('tracetool/ios')

module Tracetool
  module IOS
    describe IOSTraceScanner do
      describe '#parse' do
        let(:trace) do
          <<-IOS_TRACE
          0  My Foo Module                       0x00000001029b2d48 My Foo Module + 159048
          1  Foo                                 0x00000001029b37d0 Foo + 161744
          2  libsystem_platform.dylib            0x00000001857dbb44 _sigtramp + 52
          3  Foo                                 0x0000000102cf6178 Foo + 3580280
          4  Foo                                 0x0000000102cc36c0 Foo + 3372736
          5  UIKit                               0x000000018efc4078 <redacted> + 340
          6  UIKit                               0x000000018f903f98 <redacted> + 2364
          7  CoreFoundation                      0x0000000185b5c358 <redacted> + 24
          8  CoreFoundation                      0x0000000185b5c2d8 <redacted> + 88
          9  CoreFoundation                      0x0000000185a7a2d8 CFRunLoopRunSpecific + 436
          10  GraphicsServices                   0x000000018790bf84 GSEventRunModal + 100
          11  UIKit                              0x000000018f027880 UIApplicationMain + 208
          12  Foo                                0x0000000102995c08 Foo + 39944
          13  libdyld.dylib                      0x000000018559e56c <redacted> + 4
          IOS_TRACE
        end

        let(:expected) do
          <<-EXPECT.strip_indent.split("\n").map { |l| l.split("\t") }
          My Foo Module\t0x00000001029b2d48
          Foo\t0x00000001029b37d0
          libsystem_platform.dylib\t0x00000001857dbb44
          Foo\t0x0000000102cf6178
          Foo\t0x0000000102cc36c0
          UIKit\t0x000000018efc4078
          UIKit\t0x000000018f903f98
          CoreFoundation\t0x0000000185b5c358
          CoreFoundation\t0x0000000185b5c2d8
          CoreFoundation\t0x0000000185a7a2d8
          GraphicsServices\t0x000000018790bf84
          UIKit\t0x000000018f027880
          Foo\t0x0000000102995c08
          libdyld.dylib\t0x000000018559e56c
          EXPECT
        end

        it 'converts packed trace to atos compatible format' do
          expect(IOSTraceScanner.new.parse(trace)).to match_array(expected)
        end
      end

      describe '#process' do
        context do
          let(:launcher) do
            launcher = IOSTraceScanner.new
            example_output = <<-OUTPUT.strip_indent
            some::cpp::namespace::CppClass::method(int, int, void*) (in FooModule) (CppClass.cpp:98)
            -[FooViewController touchesEnded:withEvent:] (in FooModule) (FooViewController.mm:314)
            0X000000018559e56c
            OUTPUT
            allow(launcher).to receive(:run_atos).and_return example_output
            launcher
          end

          let(:ctx) do
            OpenStruct.new(
              load_address: '0x0',
              xarchive: 'tmp',
              module_name: 'FooModule'
            )
          end

          it 'should unpack trace' do
            input = <<-INPUT.strip_indent.chomp
            0  FooModule                           0x00000001029b37d0 FooModule + 159048
            1  FooModule                           0x00000001029b2d48 FooModule + 161744
            2  UIKit                               0x000000018559e56c _sigtramp + 52
            INPUT
            ex = <<-EXPECTED.strip_indent.chomp
            0 FooModule some::cpp::namespace::CppClass::method(int, int, void*) (in FooModule) (CppClass.cpp:98)
            1 FooModule -[FooViewController touchesEnded:withEvent:] (in FooModule) (FooViewController.mm:314)
            2 UIKit 0X000000018559e56c
            EXPECTED
            expect(launcher.process(input, ctx)).to eq(ex)
          end
        end

        context 'when has valid context' do
          let(:ctx) do
            OpenStruct.new(
              load_address: '0x0',
              xarchive: 'tmp',
              module_name: 'FooModule'
            )
          end

          let(:exec) { double }

          before do
            atos_args =
              %w[-o tmp/dSYMs/FooModule.app.dSYM/Contents/Resources/DWARF/FooModule -l 0x0 -arch arm64]
            expect(Tracetool::Pipe::Executor)
              .to receive(:new)
              .with('atos', atos_args)
              .and_return(exec)
            expect(exec).to receive(:<<).and_return('foo')
          end

          it 'runs atos with arguments' do
            expect(IOSTraceScanner.new.process('0 FooModule 0x0', ctx))
              .to eq('0 FooModule foo')
          end
        end
      end

      describe '#parser' do
        it 'returns IOSTraceParser' do
          expect(IOSTraceScanner.new.parser([])).to be_a(IOSTraceParser)
        end
      end
    end

    describe AtosContext do
      let(:ctx) do
        c = OpenStruct.new(
          module_name: 'Foo',
          xarchive: '/tmp/Foo.xarchive',
          load_address: '0x0',
          arch: 'x86_64'
        )
        AtosContext.new(c)
      end

      describe '#to_args' do
        it 'converts context to command arguments' do
          expect(ctx.to_args).to match_array(%w[
                                               -o /tmp/Foo.xarchive/dSYMs/Foo.app.dSYM/Contents/Resources/DWARF/Foo
                                               -l 0x0
                                               -arch x86_64
                                             ])
        end
      end

      describe '#initialize' do
        %i[load_address xarchive module_name]
          .each_with_object(load_address: '0x0', xarchive: 'test', module_name: 'Foo') do |argument, object|
          context "when #{argument} missing" do
            let(:ctx) { OpenStruct.new(object.dup.update(argument => nil)) }
            it 'raises exception' do
              expect { AtosContext.new(ctx) }.to raise_error(ArgumentError)
            end
          end
        end
      end
    end
  end
end
