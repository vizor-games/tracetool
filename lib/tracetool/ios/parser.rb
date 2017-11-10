require_relative '../utils/parser'

module Tracetool
  module IOS
    # IOS traces scanner and source mapper
    class IOSTraceParser < Tracetool::BaseTraceParser
      # Describes IOS stack entry
      STACK_ENTRY_PATTERN = /^(?<frame>\d+) (?<binary>[^ ]+) (?<call_description>.+)$/
      # Describes source block
      SOURCE_PATTERN =
        /^((-?\[(?<class>[^ ]+) (?<method>.+)\])|(?<method>.+)) \(in (?<module>.+)\) \((?<file>.+):(?<line>\d+)\)$/

      def initialize(files)
        super(STACK_ENTRY_PATTERN, SOURCE_PATTERN, files, true)
      end
    end
  end
end
