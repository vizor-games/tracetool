module Tracetool
  # Utility methods for working with environment
  module Env
    class << self
      # Finds executable in path
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        candidates = ENV['PATH'].split(File::PATH_SEPARATOR).flat_map do |path|
          exts.map { |ext| File.join(path, "#{cmd}#{ext}") }
        end

        candidates.find { |exe| File.executable?(exe) && !File.directory?(exe) }
      end

      # Raises exception if can't find executable in path
      # @raise [ArgumentError] if executable not found
      def ensure_command(cmd)
        raise(ArgumentError, "#{cmd} not found in PATH") unless which(cmd)
      end

      # Checks if `ndk-stack` can be found in path
      # @raise [ArgumentError] if can't find ndk-stack
      def ensure_ndk_stack
        ensure_command('ndk-stack')
      end

      # Checks if `atos` can be found in path
      # @raise [ArgumentError] if can't find atos
      def ensure_atos
        ensure_command('atos')
      end
    end
  end
end
