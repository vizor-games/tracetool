require 'powerpack/string'
require 'tmpdir'
require 'ostruct'
require 'simplecov'

# Run with coverage
SimpleCov.start

require_relative 'helpers/parser'
require_relative '../lib/tracetool/utils/env'

def lib(path)
  File.join(File.dirname(__FILE__), '../lib', path)
end

RSpec.configure do |c|
  c.include Helpers::NativeTraceParserHelper, helpers: :ndk
end
