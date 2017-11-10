require 'powerpack/string'
require 'tmpdir'
require 'ostruct'

require_relative 'helpers/parser'

def lib(path)
  File.join(File.dirname(__FILE__), '../lib', path)
end

RSpec.configure do |c|
  c.include Helpers::NativeTraceParserHelper, helpers: :ndk
end
