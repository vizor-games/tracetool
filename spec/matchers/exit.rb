RSpec::Matchers.define :exit do |expected|
  match do |actual|
    begin
      actual.call
    rescue StandardError => x
      @error = x
    rescue SystemExit => x
      @error = x
    end

    @error.is_a?(SystemExit) && @error.status == expected
  end

  def supports_block_expectations?
    true
  end

  description do
    %(exit with code #{expected})
  end

  def failure_message(to = 'to')
    got = if @error.is_a? SystemExit
            'code ' + @error.status.to_s
          else
            @error.class.name + '("' + @error.message + '")'
          end
    %(expected #{to} #{description} but got #{got})
  end
end
