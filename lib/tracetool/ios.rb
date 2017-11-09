module Tracetool
  # IOS trace unpacking routines
  module IOS
    # Parses iOS thread stack trace
    # @see [Understanding and Analyzing Application Crash Reports](https://developer.apple.com/library/content/technotes/tn2151/_index.html)
    class IOSTraceParser
      # Stack trace line consists of numerous whitespace separated
      # columns. First three always are:
      #
      # * frame #
      # * binary name
      # * address
      # @param [String] trace string containing stack trace
      # @returns [Array] containing (%binary_name%, %address%) pairs
      def parse(trace)
        trace.split("\n").map do |line|
          line.split(' ')[1..2] # Fetch binary name and address
        end
      end
    end

    # Converts context to atos arguments
    class AtosContext
      # If no arch specified will use `arm64`
      DEFAULT_ARCH = 'arm64'.freeze

      # List of required argument names
      REQUIRED_ARGUMENTS = %i[load_address xarchive module_name].freeze

      #
      def initialize(ctx)
        check_arguments(ctx)
        @load_address = ctx.load_address
        @binary_path = module_binary(ctx.xarchive, ctx.module_name)
        @arch = ctx.arch || 'arm64'
      end

      def to_args
        %w[-o -l -arch].zip([@binary_path, @load_address, @arch]).flatten
      end

      private

      def module_binary(xarchive, module_name)
        File.join(xarchive, 'dSYMs', "#{module_name}.app.dSYM", 'Contents', 'Resources', 'DWARF', module_name)
      end

      def check_arguments(ctx)
        REQUIRED_ARGUMENTS.each do |a|
          ctx[a] || raise(ArgumentError, "Missing `#{a}` value")
        end
      end
    end

    # launches atos
    class AtosLauncher
      def process(trace, context)
        desym = run_atos(context, trace.map(&:first))
        # Add useful columns to unpacked trace
        #
        mix(trace, desym.split("\n")).join("\n")
      end

      def run_atos(context, trace)
        Pipe['atos', *AtosContext.new(context).to_args] << trace
      end

      def mix(trace, symbolicated)
        trace.zip(symbolicated).map.with_index do |pair, i|
          t, desym = pair
          line = []
          line << i
          line << t.first
          line << desym

          line.join(' ')
        end
      end
    end
    # IOS uncpacker class
    class IOSUnpacker
      def scan(stack, arch, symbols, modulename, address)
        sym_path = symbols_path(symbols, modulename)
        functions = stack
                    .gsub('\n', "\n")
                    .split("\n")
                    .map { |line| line.sub(modulename, '').split(' ') }
                    .map { |_, func_address| func_address }

        reformat(atos(sym_path, address, arch, functions), modulename)
      end

      def reformat(lines, modulename)
        lines = lines.split("\n")
        w = Math.log10(lines.size).to_i + 1

        lines.map.with_index do |line, index|
          "#%#{w}d %s :: %s".format(index, modulename, line)
        end
      end

      def symbols_path(xarchive, modulename)
        File.join(xarchive, 'dSYMs', "#{modulename}.app.dSYM", 'Contents', 'Resources', 'DWARF', modulename)
      end

      def atos(sym_path, address, arch, functions)
        `atos -o #{sym_path} -l #{address} -arch #{arch} #{functions.join(' ')}`.chomp
      end
    end

    def self.scan(stack, arch, symbols, modulename, address)
      IOSUnpacker.new.scan(stack.gsub('\n', "\n"), arch, symbols, modulename, address)
    end
  end
end
