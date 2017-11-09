# Tracetool root module
module Tracetool
  # Android trace scan variant
  module Android
    # Converts packed trace to ndk-stack compatible trace
    class NdkPackedTraceConverter
      # Default header for android backtrace
      NATIVE_DUMP_HEADER = <<-BACKTRACE.strip_indent
      *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
      Build fingerprint: UNKNOWN
      pid: 0, tid: 0
      signal 0 (UNKNOWN)
      backtrace:
      BACKTRACE

      # Converts packed stack trace into ndk-stack compatible format
      # @param [String] trace packed stack trace
      # @param [] _context not used
      def process(trace, _context)
        dump_body = prepare(trace).map.with_index { |line, index| convert_line(line, index) }
        NATIVE_DUMP_HEADER + dump_body.join("\n")
      end

      private

      def prepare(trace)
        trace.gsub('>>><<<', '')[/<<<(.+)>>>/, 1].split(';')
      end

      def convert_line(line, index)
        frame = index
        addr = line[/^(-?\d+) (.*)$/, 1]
        lib = line[/^(-?\d+) (.*)$/, 2].strip
        '    #%02i  pc %08x  %s'.format(frame, addr, lib)
      end
    end

    # Desymbolicates stack trace using ndk-stack from
    # Android NDK
    class NdkStackLauncher
      # @see https://developer.android.com/ndk/guides/ndk-stack.html
      # @param [String] trace stack trace in ndk-stack compatible
      #  format
      # @param [OpenStruct] ctx context containing path to symbols
      # @return [String] desymbolicated stack trace
      def process(trace, ctx)
        Pipe['ndk-stack', '-sym', ctx.symbols] << trace
      end
    end


    def self.scan(stack, symbols)
      router = AndroidRouter.new(OpenStruct.new(symbols: symbols))

      router.java do |trace, ctx|
        process(trace, ctx)
      end

      router.ndk do |trace, ctx|
        process(trace, ctx, NdkStackLauncher.new)
      end

      router.packed_ndk do |trace, ctx|
        process(trace, ctx, NdkPackedTraceConverter.new, NdkStackLauncher.new)
      end

      router.handle(stack)
    end

    def process(trace, ctx, *queue)
      queue.inject(trace) { |acc, elem| elem.process(acc, ctx) }
    end
  end
end
