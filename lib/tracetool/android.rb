require_relative 'android/java'
require_relative 'android/native'

# Tracetool root module
module Tracetool
  # Android trace scan variant
  module Android
    # Desymbolicates android traces
    class AndroidTraceScanner
      # List of scanners
      SCANNERS = [JavaTraceScanner, NativeTraceScanner].freeze

      # Launches process of trace desymbolication
      # @param [String] trace trace body
      def process(trace, context)
        # Find scanner which matches trace format
        @scanner = SCANNERS.map { |s| s[trace] }.compact.first
        raise(ArgumentError, "#{trace}\n not android trace?") unless @scanner
        @scanner.process(context)
      end

      # Creates parser for last unpacked trace
      # @param [Array] files list of source files used in build
      # @return [Tracetool::BaseTraceParser] parser that matches trace format.
      #   Or `nil`. If there was no scanning.
      def parser(files)
        return unless @scanner
        @scanner.parser(files)
      end
    end

    class << self
      # Desymbolicate android stack trace
      def scan(string, opts = {})
        AndroidTraceScanner.new.process(string, OpenStruct.new(opts))
      end
    end
  end
end
