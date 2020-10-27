module Tracetool
  module IOS
    # launches atos
    class IOSTraceScanner
      # Stack trace line consists of numerous whitespace separated
      # columns. First three always are:
      #
      # * frame #
      # * binary name
      # * address
      # @param [String] trace string containing stack trace
      # @return [Array] containing (%binary_name%, %address%) pairs
      def parse(trace)
        trace.split("\n").map do |line|
          parse_line(line)
        end
      end

      # Parse trace line from trace. Which usualy looks like this:
      #   3   My Module Name      0x0000000102d6e9f4 My Module Name + 5859828
      # We need to fetch two values: 'My Module Name' and '0x0000000102d6e9f4'.
      def parse_line(line)
        parts = line.split(' ')
        parts.shift # Frame number, not needed

        module_name = ''

        until parts.first.start_with?('0x')
          module_name += parts.shift
          module_name += ' '
        end

        address = parts.shift

        [module_name.chop, address]
      end

      def process(trace, context)
        trace = parse(trace)
        desym = run_atos(context, trace.map(&:last).join('  '))
        # Add useful columns to unpacked trace
        mix(trace, desym.split("\n")).join("\n")
      end

      def run_atos(context, trace)
        Pipe['atos', *AtosContext.new(context).to_args] << trace
      end

      # Create parser for current trace format
      # @param [Array] files list of files used in build. This files are
      #   used to match file entries from stack trace to real files
      # @return [Tracetool::BaseTraceParser] parser that matches trace format
      def parser(files)
        IOSTraceParser.new(files)
      end

      private

      def mix(trace, symbolicated)
        trace.zip(symbolicated).map.with_index do |pair, i|
          t, desym = pair
          "#{i}\t#{t.first}\t#{desym}"
        end
      end
    end
  end
end
