require_relative '../utils/parser'

module Tracetool
  module Android
    # Android traces scanner and mapper
    class NativeTraceParser < Tracetool::BaseTraceParser
      # Describes android stack entry
      STACK_ENTRY_PATTERN =
        %r{Stack frame #(?<frame>\d+)  (?<address>\w+ [a-f\d]+)  (?<lib>[/\w\d\.=-]+)( )?(:? (?<call_description>.+))?$}
        .freeze
      # Describes android native method call (class::method and source file with line number)
      CALL_PATTERN = [
        /((Routine )?(?<method>.+) ((in)|(at)) (?<file>.+):(?<line>\d+))/,
        /(?<method>.+?) \d+/
      ].freeze

      def initialize(files)
        super(STACK_ENTRY_PATTERN, CALL_PATTERN, files, true)
      end
    end

    # Methods for stack trace string normalization
    module NativeTraceEnhancer
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
      # @return well formed stack trace
      def unpack(trace)
        dump_body = prepare(trace)
                    .map
                    .with_index { |line, index| convert_line(line, index) }
        add_header(dump_body.join("\n"))
      end

      # Add dummy header for stack trace body
      def add_header(string)
        NATIVE_DUMP_HEADER + sanitize(string)
      end

      private

      def prepare(trace)
        trace.gsub('>>><<<', '')[/<<<(.+)>>>/, 1].split(';')
      end

      def convert_line(line, index)
        frame = index
        addr = line[/^(-?\d+) (.*)$/, 1]
        lib = (line[/^(-?\d+) (.*)$/, 2] || '').strip # nil safe
        '    #%02<frame>i  pc %08<addr>x  %<lib>s'
          .format(frame: frame, addr: addr, lib: lib)
      end

      # If needed here we'll drop all unneeded leading characters from each
      # stack trace line. This may be needed to add NATIVE_DUMP_HEADER
      # correctly
      def sanitize(string)
        string
      end
    end

    # Processes native traces
    class NativeTraceScanner
      # Initial sequence of asterisks which marks begining of trace body
      TRACE_DELIMETER =
        '*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***'.freeze
      RX_INITIAL_ASTERISKS = /#{TRACE_DELIMETER.gsub('*', '\*')}/.freeze
      # Contains address line like
      #
      # ```
      # pc 00000000004321ec libfoo.so
      # ```
      RX_PC_ADDRESS = /pc \d+/.freeze

      # Format of packed trace.
      # Consists of one or more trace blocks.
      # * Each block starts with `<<<` and ends with `>>>`.
      # * Each block contains one or more lines
      # * Lines delimited with ;
      # * Line consists of
      # ** pointer address `/\d+/`
      # ** library (so) name `/[^ ]+/`
      # ** symbol name `/[^ ]+/`, if present
      # ** symbol offset `/\d+/`
      #
      # Last two entries can be missing.
      RX_PACKED_FORMAT = /^(<<<([-\d]+ [^ ]+ (.+)?;)+>>>)+$/.freeze

      # @param [String] string well formed native android stack trace
      # @see https://developer.android.com/ndk/guides/ndk-stack.html
      def initialize(string)
        @trace = string
      end

      # @param [OpenStruct] ctx context object containing `symbols` field with
      #   path to symbols dir
      # @return [String] desymbolicated stack trace
      def process(ctx)
        symbols = File.join(ctx.symbols, 'local')
        symbols = if ctx.arch
                    File.join(symbols, ctx.arch)
                  else
                    Dir[File.join(symbols, '*')].first || symbols
                  end
        Pipe['ndk-stack', '-sym', symbols] << @trace
      end

      # Create parser for current trace format
      # @param [Array] files list of files used in build. This files are
      #   used to match file entries from stack trace to real files
      # @return [Tracetool::BaseTraceParser] parser that matches trace format
      def parser(files)
        NativeTraceParser.new(files)
      end

      class << self
        # Add methods for trace normalization
        include Tracetool::Android::NativeTraceEnhancer
        def packed?(string)
          RX_PACKED_FORMAT.match(string)
        end

        def without_header?(string)
          lines = string.split("\n")
          return true if address_lines?(lines)

          first, *rest = lines
          first.include?('backtrace:') && address_lines?(rest)
        end

        def address_lines?(lines)
          lines.all? do |line|
            RX_PC_ADDRESS.match(line)
          end
        end

        def with_header?(string)
          RX_INITIAL_ASTERISKS.match(string)
        end

        # With given potential stack trace string
        # create scanner if possible
        # @param [String] string trace
        # @return [NativeTraceScanner] or nil
        def [](string)
          if packed? string
            new(unpack(string))
          elsif with_header? string
            new(string)
          elsif without_header? string
            new(add_header(string))
          end
        end
      end
    end
  end
end
