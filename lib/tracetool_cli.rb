require_relative 'tracetool'
require_relative 'tracetool/utils/cli'

opts = Tracetool::ParseArgs.parse(ARGV)
case opts.platform
when :android
  stack = ARGF.read
  puts Tracetool::Android.scan(stack,
                               symbols: opts.sym_dir,
                               arch: opts.arch.to_s)
when :ios
  stack = ARGF.read
  puts Tracetool::IOS.scan(stack,
                           arch: opts.arch.to_s,
                           xarchive: opts.sym_dir,
                           module_name: opts.modulename,
                           load_address: opts.address)
else
  raise "Unknown(#{opts.platform})"
end
