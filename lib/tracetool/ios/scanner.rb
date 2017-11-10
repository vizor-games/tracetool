module Tracetool
  module IOS
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
    class IOSTraceScanner
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

      def process(trace, context)
        trace = parse(trace)
        desym = run_atos(context, trace.map(&:first))
        # Add useful columns to unpacked trace
        mix(trace, desym.split("\n")).join("\n")
      end

      def run_atos(context, trace)
        Pipe['atos', *AtosContext.new(context).to_args] << trace
      end

      private

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
  end
end
