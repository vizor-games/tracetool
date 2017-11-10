module Tracetool
  module Android
    # Processes native traces
    class NativeTraceScanner
      # Initial sequence of asterisks which marks begining of trace body
      TRACE_DELIMETER = '*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***'.freeze
      RX_INITIAL_ASTERISKS = /^.+ #{TRACE_DELIMETER.gsub('*', '\*')}$/
      # Contains address line like
      #
      # ```
      # pc 00000000004321ec libfoo.so
      # ```
      RX_PC_ADDRESS = /pc \d+/

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
      RX_PACKED_FORMAT = /^(<<<(\d+ [^ ]+ ([^ ]+ \d+)?;)+>>>)+$/
      class << self
        # Tells if provided string is a ndk trace
        # @return [MatchResult]
        def match(string)
          return false if string.empty?
          packed?(string) || with_header?(string) || without_header?(string)
        end

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
      end
    end
  end
end
