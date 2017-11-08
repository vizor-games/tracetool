module Tracetool
  # IOS trace unpacking routines
  module IOS
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
