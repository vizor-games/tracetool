require 'open3'
module Tracetool
  module Pipe
    class Executor
      def initialize(cmd, *args)
        @cmd = cmd
        @args = args
      end

      def cmd
        [@cmd, @args].flatten
      end

      def <<(args)
        args = args.join("\n") if args.is_a? Array
        IO.popen(cmd, 'r+') do |io|
          io.write(args)
          io.close_write
          io.read.chomp
        end
      end
    end

    class << self
      def[](cmd, *args)
        Executor.new(cmd, args)
      end
    end
  end
end