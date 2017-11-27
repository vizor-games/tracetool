module Tracetool
  # Version constant
  module Version
    VERSION = [0, 3, 0].freeze

    class << self
      # @return [String] version string
      def to_s
        VERSION.join('.')
      end
    end
  end
end
