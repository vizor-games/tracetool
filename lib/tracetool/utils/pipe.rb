require 'open3'

module Tracetool
  # Helper module for launching commands
  module Pipe
    # Executes shell command
    class Executor
      def initialize(cmd, *args)
        @cmd = cmd
        @args = args
      end

      def cmd
        [@cmd, @args].flatten
      end

      def <<(args)
        out, err, status = Open3.capture3({}, *cmd, stdin_data: args)
        raise "#{cmd.join(' ')} (exit: #{status.exitstatus}) #{err.chomp}" unless status.success?

        out.chomp
      end
    end

    class << self
      def[](cmd, *args)
        Executor.new(cmd, args)
      end
    end
  end
end
