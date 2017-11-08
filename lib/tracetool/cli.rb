require 'optparse'
require 'optparse/time'
require 'ostruct'

module Tracetool
  # Tracetool cli args parser
  class ParseArgs
    #
    # Return a structure describing the options.
    #
    def self.parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.
      opt_parser = ParseArgs.new(OpenStruct.new(sym_dir: Dir.pwd))
      options = opt_parser.parse(args)
      check(options, opt_parser.help)
      check_ios(options, opt_parser.help)
      options
    end

    def self.check_ios(options, message)
      return unless options.platform == :ios
      {
        'address' => options.address,
        'modulename' =>  options.modulename
      }.each { |arg, check| raise(OptionParser::MissingArgument, arg) unless check }
    rescue OptionParser::MissingArgument => x
      puts ["Error occured: #{x.message}", '', message].join("\n")
      exit 2
    end

    def self.check(options, message)
      {
        'platform' => options.platform,
        'arch' => options.arch
      }.each { |arg, check| raise(OptionParser::MissingArgument, arg) unless check }
    rescue OptionParser::MissingArgument => x
      puts ["Error occured: #{x.message}", '', message].join("\n")
      exit 2
    end

    def initialize(defaults)
      @options = defaults
      @opt_parser = OptionParser.new do |opts|
        opt_banner(opts)
        opts.separator ''
        opt_common(opts)
        opts.separator ''
        opt_ios(opts)
        opts.separator ''
        opt_default(opts)
      end
    end

    def parse(args)
      @opt_parser.parse!(args)
      @options
    end

    def help
      @opt_parser.help
    end

    def opt_banner(opts)
      opts.banner = 'Usage: tracetool OPTION... [FILE]...'
      opts.separator ''
      opts.separator 'Examples:'
      opts.separator "\techo '<<<...>>>' | tracetool --arch armeabi-v7a --platform android  --symbols %build_dir%"
      opts.separator "\ttracetool --platform ios --arch arm64 --address 0x100038000 --module ZombieCastaways dump"
    end

    def opt_common(opts)
      opts.separator 'Common options:'
      # Specify arch
      opts.on('--arch ARCH', [:'armeabi-v7a', :armeabi, :x86, :arm64], 'Specify arch (armeabi-v7a, x86, arm64)') do |arch|
        @options.arch = arch
      end

      # Specify platform
      opts.on('--platform PLATORM', [:android, :ios], 'Specify platform (android, ios)') do |platform|
        @options.platform = platform
      end

      # Symbols dir
      opts.on('--symbols [SYMBOLS]', 'Symbols dir. Using current working dir if not specified') do |dir|
        @options.sym_dir = dir
      end
    end

    def opt_ios(opts)
      opts.separator 'IOS specific options'
      # Addres
      opts.on('--address ADDRESS', 'Baseline address for ios builds') do |address|
        @options.address = address
      end

      # Modulename -- execution entry point
      opts.on('--module MODULENAME', 'Entry point for ios builds') do |modulename|
        @options.modulename = modulename
      end
    end

    def opt_default(opts)
      opts.separator 'Base options:'
      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      # Another typical switch to print the version.
      opts.on_tail('--version', 'Show version') do
        puts 'tracetool ' + Tracetool::Version.join('.')
        exit
      end
    end
  end
end
