require_relative lib('tracetool/android/java')

module Tracetool
  module Android
    describe JavaTraceScanner do
      describe '#match' do
        let(:matcher) { JavaTraceScanner }

        Dir[File.join(__dir__, 'fixtures', 'scanner_*')].each do |file|
          context_title, *lines = IO.read(file).split("\n")
          context context_title do
            it { expect(matcher.match(lines.join("\n"))).to be_truthy }
          end
        end
      end

      describe '#parser' do
        it 'creates JavaTraceParser' do
          expect(JavaTraceScanner.new("java.lang.OutOfMemoryError: Try again\n").parser([]))
            .to be_a(JavaTraceParser)
        end
      end
    end
  end
end
