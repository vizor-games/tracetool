require_relative '../utils/parser'

module Tracetool
  module Android
    # Parses java stack traces
    class JavaTraceParser < Tracetool::BaseTraceParser
      # Describes java stack entry
      STACK_ENTRY_PATTERN = /^(\s+at (?<call_description>.+))|((?<error>.+?): (?<message>.+))$/
      # Describes java method call
      CALL_PATTERN = /(?<class>.+)\.(?<method>[^\(]+)\((((?<file>.+\.java):(?<line>\d+))|(?<location>.+))\)$/

      def initialize(files)
        super(STACK_ENTRY_PATTERN, CALL_PATTERN, files, true)
      end
    end
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
          new(string) if match(string)
        end
      end
    end
  end
end
