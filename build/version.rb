module Tracetool
  # Collection of build helpers
  module Build
    # Finds version description in ruby file and updates its value
    class Bumper
      # @param [String] version_file path to file
      def initialize(version_file)
        @file = version_file
      end

      # Updates version number in loaded file
      # @param [Integer] major major version increment
      # @param [Integer] minor minor version increment
      # @param [Integer] patch path version increment
      def bump(major: 0, minor: 0, patch: 0)
        patched = IO.read(@file).gsub(/VERSION = (\[\d+, \d+, \d+\])/) do |m|
          # rubocop:disable Security/Eval
          old_version = eval(m[/\[\d+, \d+, \d+\]/])
          # rubocop:enable Security/Eval
          new_version = bump_version_array(old_version, major, minor, patch)
          "VERSION = [#{new_version.join(', ')}]"
        end

        IO.write(@file, patched)
      end

      private

      def bump_version_array(version, major, minor, patch)
        version = [version[0] + major, 0, 0] if major.positive?
        version = [version[0], version[1] + minor, 0] if minor.positive?
        version = [version[0], version[1], version[2] + patch] if patch.positive?

        version
      end
    end
  end
end
