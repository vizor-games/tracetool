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
        ma, mi, pa = version
        if major != 0
          bump_version_array([ma + major, 0, 0], 0, minor, patch)
        elsif minor != 0
          bump_version_array([ma, mi + minor, 0], 0, 0, patch)
        elsif patch != 0
          [ma, mi, pa + patch]
        else
          [ma, mi, pa]
        end
      end
    end
  end
end
