require 'powerpack/string/strip_ident'

# Tracetool root module
module Tracetool
  # Android trace scan variant
  module Android
    # Supported arch list
    module Arch
      def self.include?(arch)
        @arch_list.include?(arch)
      end

      def self.all
        @arch_list
      end

      @arch_list = %w(armeabi-v7a x86 armeabi).freeze
    end

    # Android unpacker implementation
    class AndroidUnpacker
      # Backtrace initial line of asterisks. Required marker for ndk-stack.
      NATIVE_DUMP_DELIMETER = '*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***'.freeze
      # Template for android backtrace
      NATIVE_DUMP_HEADER = <<-BACKTRACE.strip_ident
      *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
      backtrace:
      BACKTRACE

      def initialize(stack, arch, symbols)
        # Нужно убрать joinы стеков, это один и тот же трейс
        # А потом выбрать только тело трейса
        @stack = stack.gsub('>>><<<', '')[/<<<(.*)>>>/, 1]
        @arch = arch
        # Символы лежат в local/arch
        @symbols = File.join(symbols, 'local', arch)
        raise "No such dir #{@symbols}" unless File.exist?(@symbols)
      end

      def scan
        dump_body = @stack
                    .split(';')
                    .map
                    .with_index { |line, index| convert_line(line, index) }
                    .join("\n")
        dump = [DUMP_HEADER, dump_body].join("\n")
        `echo '#{dump}' | ndk-stack -sym #{@symbols}`.chomp
      end

      private

      def convert_line(line, index)
        frame = index
        addr = line[/^(-?\d+) (.*)$/, 1]
        lib = line[/^(-?\d+) (.*)$/, 2].strip
        '    #%02i  pc %08x  %s'.format(frame, addr, lib)
      end
    end

    def self.scan(stack, arch, symbols)
      arch_valid = Arch.include?(arch)
      arch_all = Arch.all.join(',')
      
      raise "Arch should be one of #{arch_all}" unless arch_valid

      raise "No such directory #{symbols}" unless File.exist?(symbols)
      raise "Not a directory #{symbols}" unless File.directory?(symbols)
      AndroidUnpacker.new(stack, arch, symbols).scan
    end
  end
end
