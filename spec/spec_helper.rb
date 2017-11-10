require 'powerpack/string'
require 'tmpdir'
require 'ostruct'

def lib(path)
  File.join(File.dirname(__FILE__), '../lib', path)
end
