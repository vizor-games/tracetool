require 'powerpack/string'
require 'tmpdir'
require 'ostruct'

require 'simplecov'
require 'rspec/matchers/fail_matchers'

SimpleCov.start

require_relative 'matchers/exit'
require_relative 'helpers/parser'

require_relative '../lib/tracetool/utils/env'

def lib(path)
  File.join(__dir__, '../lib', path)
end

def build(path)
  File.join(__dir__, '../build', path)
end

RSpec.configure do |c|
  c.include Helpers::NativeTraceParserHelper, helpers: :ndk
  c.include RSpec::Matchers::FailMatchers, fail_matchers: true
end
