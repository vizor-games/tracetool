RSpec::Matchers.define :exit do |expected|
  match do |actual|
    begin
      actual.call
    rescue SystemExit => x
      @error = x
    end

    @error.is_a?(SystemExit) && @error.status == 0
  end

  def supports_block_expectations?
    true
  end

  description do
    %(exit with code #{expected})
  end

  def failure_message(to = 'to')
    got = if @error.is_a? SystemExit
            'code ' + @error.status
          else
            @error
          end
    %(expected #{to} #{description} but got #{got})
  end
end
