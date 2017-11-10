module Tracetool
  module Android
    # Processes java traces
    class JavaTraceScanner
      RX_FIRST_EXCEPTION_LINE = /^.+$/
      RX_OTHER_EXCEPTION_LINE = /at [^(]+\(([^:]+:\d+)|(Native Method)\)$/

      def initialize(string)
        @trace = string
      end

      def process(_ctx)
        @trace
      end

      class << self
        def match(string)
          # Split into lines
          first, *rest = string.split("\n")

          return if rest.nil? || rest.empty?
          return unless RX_FIRST_EXCEPTION_LINE.match(first)

          rest.all? { |line| RX_OTHER_EXCEPTION_LINE.match(line) }
        end

        def [](string)
          return new(string) if match(string)
        end
      end
    end
  end
end
