require_relative 'tracetool/android'
require_relative 'tracetool/ios'
require_relative 'tracetool/version'
require_relative 'tracetool/cli'

opts = Tracetool::ParseArgs.parse(ARGV)

case opts.platform
when :android
  ARGF.read.split("\n").each do |stack|
    puts Tracetool::Android.scan(stack, opts.arch.to_s, opts.sym_dir)
    puts '----'
  end
when :ios
  ARGF.read.split("\n").each do |stack|
    puts Tracetool::IOS.scan(stack, opts.arch.to_s, opts.sym_dir, opts.modulename, opts.address)
  end
else
  raise "Unknown(#{opts.platform})"
end
