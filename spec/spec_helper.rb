require 'powerpack/string'
require 'tmpdir'

def lib(path)
  File.join(File.dirname(__FILE__), '../lib', path)
end

require_relative lib('tracetool/router')

module RSpecHelpers
  def strict_android_router(ctx = OpenStruct.new)
    router = Tracetool::AndroidRouter.new(ctx)
    Tracetool::AndroidRouter::ROUTES.each_value do |v|
      router.on(v) do
        raise(ArgumentError, "'#{v}' should not be called")
      end
    end
    router
  end
end

RSpec.configure do |c|
  c.include RSpecHelpers, fixture: :router
end
