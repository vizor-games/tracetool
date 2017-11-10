require_relative '../utils/parser'

module Tracetool
  module IOS
    # IOS traces scanner and source mapper
    class IOSTraceParser < Tracetool::BaseTraceParser
      # Describes IOS stack entry
      STACK_ENTRY_PATTERN = /^#(\s+)?(?<frame>\d+) (?<lib>.+) :: (?<call_description>.+)$/
      # Describes source block
      SOURCE_PATTERN = /^((?<method>.+) \(in (?<lib>.+)\) \((?<file>.+):(?<line>\d+)\))|(?<other>.+)$/

      def initialize(files)
        super(STACK_ENTRY_PATTERN, SOURCE_PATTERN, files)
      end
    end
  end
end
