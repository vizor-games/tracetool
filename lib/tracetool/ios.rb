require_relative 'ios/scanner'
require_relative 'ios/parser'

module Tracetool
  # IOS trace unpacking routines
  module IOS
    def self.scan(string, opts)
      IOSTraceScanner.new.process(string, OpenStruct.new(opts))
    end
  end
end
