require 'ostruct'
require 'powerpack/string'

require_relative 'tracetool/android'
require_relative 'tracetool/ios'
require_relative 'tracetool/utils/cli'
require_relative 'tracetool/utils/env'
require_relative 'tracetool/utils/pipe'

opts = Tracetool::ParseArgs.parse(ARGV)

case opts.platform
  when :android
    ARGF.read.split("\n").each do |stack|
      puts Tracetool::Android.scan(stack, symbols: opts.sym_dir)
    end
  when :ios
    ARGF.read.split("\n").each do |stack|
      puts Tracetool::IOS.scan(stack,
                               arch: opts.arch.to_s,
                               xarchive: opts.sym_dir,
                               module_name: opts.modulename,
                               load_address: opts.address)
    end
  else
    raise "Unknown(#{opts.platform})"
end