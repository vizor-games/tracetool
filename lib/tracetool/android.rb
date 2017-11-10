require_relative 'android/java/scanner'
require_relative 'android/java/parser'

require_relative 'android/native/scanner'
require_relative 'android/native/parser'

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
        # Find scanner which maches trace format
        scanner = SCANNERS.map { |s| s[trace] }.compact.first
        raise(ArgumentError, "#{trace}\n not android trace?") unless scanner
        scanner.process(*context)
      end
    end

    class << self
      # Desymbolicate android stack trace
      def desym(string, opts = {})
        AndroidTraceScanner.process(string, opts)
      end
    end
  end
end
