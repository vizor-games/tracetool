module Tracetool
  # Set of utility methods for working with strings
  module StringUtils
    # Extended string class
    # rubocop:disable Style/ClassAndModuleChildren
    class ::String
      # Return longest common postfix
      # @param [String] other other string to match
      # @return [String] longest common postfix
      def longest_common_postfix(other)
        sidx = length - 1
        oidx = other.length - 1

        while sidx >= 0 && oidx >= 0 && (self[sidx] == other[oidx])
          sidx -= 1
          oidx -= 1
        end

        other[(oidx + 1)..-1]
      end
    end
    # rubocop:enable Style/ClassAndModuleChildren
  end
end
