require 'ostruct'

module Tracetool
  # Matches plain java trace
  class AndroidJavaMatcher
    RX_FIRST_EXCEPTION_LINE = /^.+$/
    RX_OTHER_EXCEPTION_LINE = /at [^(]+\(([^:]+:\d+)|(Native Method)\)$/
    def match(string)
      # Split into lines
      first, *rest = string.split("\n")

      return if rest.nil? || rest.empty?
      return unless RX_FIRST_EXCEPTION_LINE.match(first)

      rest.all? { |line| RX_OTHER_EXCEPTION_LINE.match(line) }
    end
  end

  # Matches native trace which you can see in logcat messages
  # @see https://developer.android.com/ndk/guides/ndk-stack.html
  class AndroidNdkMatcher
    # Initial sequence of asterisks which marks begining of trace body
    TRACE_DELIMETER = '*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***'.freeze
    RX_TRACE_DELIMETER = /^.+ #{TRACE_DELIMETER.gsub('*', '\*')}$/
    # Tells if provided string is a ndk trace
    # @return [MatchResult]
    def match(string)
      RX_TRACE_DELIMETER.match(string)
    end
  end

  # Matches packed native trace
  class AndroidNdkPackedMatcher
    # Format of packed trace.
    # Consists of one or more trace blocks.
    # * Each block starts with `<<<` and ends with `>>>`.
    # * Each block contains one or more lines
    # * Lines delimited with ;
    # * Line consists of
    # ** pointer address `/\d+/`
    # ** library (so) name `/[^ ]+/`
    # ** symbol name `/[^ ]+/`, if present
    # ** symbol offset `/\d+/`
    #
    # Last two entries can be missing.
    RX_PACKED_FORMAT = /^(<<<(\d+ [^ ]+ ([^ ]+ \d+)?;)+>>>)+$/

    def match(string)
      RX_PACKED_FORMAT.match(string)
    end
  end

  # Abstract schema for stack trace processing
  class Router
    def initialize(context, routes)
      @ctx = context
      @routes = routes
      # Return original string by default
      @switches = routes.values.inject({}) { |acc, v| acc.update(v => ->(s, _ctx) { s }) }
    end

    # Read whole trace string and tries to guess which parameters should be
    # used to unpack this trace
    # @param [String] string string containing trace
    # @return
    def handle(string)
      _matcher, switch = @routes
                         .select { |matcher, _route| matcher.match(string) }
                         .first
      @switches[switch].call(sanitize(string), @ctx)
    end

    # Using `#on` method we create initialize
    # processing pipeline
    # @see ROUTES
    # @param [Symbol] switch from ROUTES values
    def on(switch, &block)
      @switches[switch] = block
      self # Return self for chaining
    end

    private

    # Replaces "\\n" with "\n"
    # Replaces "\\t" with "\t"
    def sanitize(string)
      string.gsub('\n', "\n").gsub('\t', "\t")
    end
  end

  # Parses string with android  stack trace and routes
  # it to proper handler
  class AndroidRouter < Router
    # Determines which route should be used
    # to process trace
    ROUTES = {
      AndroidJavaMatcher.new => :java,
      AndroidNdkMatcher.new => :ndk,
      AndroidNdkPackedMatcher.new => :packed_ndk
    }.freeze

    # Generate sugar methods
    ROUTES.each_value do |v|
      eval(<<-METH.strip_indent
           def #{v}(&block)
             on(:#{v}, &block)
           end
      METH
          )
    end

    def initialize(ctx = OpenStruct.new)
      super(ctx, ROUTES)
    end
  end

  # Parses string with ios stack trace and routes
  # it to proper handler
  class IOSRouter < Router
    ROUTES = {
      /.+/ => :ios
    }.freeze

    # Generate sugar methods
    ROUTES.each_value do |v|
      eval(<<-METH.strip_indent
           def #{v}(&block)
             on(:#{v}, &block)
           end
      METH
          )
    end

    def initialize(ctx = OpenStruct.new)
      super(ctx, ROUTES)
    end
  end
end
