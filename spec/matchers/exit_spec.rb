require_relative 'exit'

module RSpec
  module Matchers
    describe 'exit matcher', fail_matchers: true do
      it { expect { Kernel.exit(2) }.to exit(2) }
      it do
        expect { expect { Kernel.exit(2) }.to exit(1) }
          .to fail_with(/expected to exit with code 1 but got code 2/)
      end

      it do
        expect { expect { raise(ArgumentError, 'Boom!') }.to exit(1) }
          .to fail_with(/expected to exit with code 1 but got ArgumentError\("Boom!"\)/)
      end
    end
  end
end
