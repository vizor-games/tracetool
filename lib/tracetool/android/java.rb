require_relative '../utils/parser'

module Tracetool
  module Android
    # Parses java stack traces
    class JavaTraceParser < Tracetool::BaseTraceParser
      # Describes java stack entry
      STACK_ENTRY_PATTERN = /^(\s+at (?<call_description>.+))|((?<error>.+?): (?<message>.+))$/.freeze
      # Describes java method call
      CALL_PATTERN = /(?<class>.+)\.(?<method>[^\(]+)\((((?<file>.+\.java):(?<line>\d+))|(?<location>.+))\)$/.freeze

      def initialize(files)
        super(STACK_ENTRY_PATTERN, CALL_PATTERN, files, true)
      end
    end
    # Processes java traces
    class JavaTraceScanner
      # Usually java trace starts with
      #   com.something.SomeClass(: Some message)?
      RX_FIRST_EXCEPTION_LINE = /^([a-zA-Z.]*)(:.*)?$/.freeze

      # Rest is expanded as
      #   at com.other.OtherClass.someMethod(OtherClass.java:42)
      # Source marker can be just "Native Method" or "Unknown Source"
      RX_OTHER_EXCEPTION_LINE = /((at [a-zA-Z$.]+)|(Caused by:)|(\.\.\. [0-9]* more))(.+)?$/.freeze

      def initialize(string)
        @trace = string
      end

      def process(_ctx)
        @trace
      end

      # Create parser for current trace format
      # @param [Array] files list of files used in build. This files are
      #   used to match file entries from stack trace to real files
      # @return [Tracetool::BaseTraceParser] parser that matches trace format
      def parser(files)
        JavaTraceParser.new(files)
      end

      class << self
        def match(string)
          # Split into lines
          first, *rest = string.split("\n")
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
