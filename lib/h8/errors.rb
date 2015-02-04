module H8

  # The exception that H8 raises on errors that are not caused by executing
  # javascript (e.g. bad parameters, illegal conversion and so on)
  class Error < StandardError
  end

  # The general error caused by the script execution, e.g. uncaught javascript exceptinos and like.
  # Check #message to see the cause.
  class JsError < Error

    # Javascript Error object. May be nil
    attr :javascript_error, :origin_name, :origin_line, :origin_column

    # Error name
    def name
      @javascript_error.name ? @javascript_error.name : @message
    end

    # String that represents stack trace if any as multiline string (\n separated)
    def javascript_backtrace
      if @javascript_error
        s = @javascript_error.stack
        if s !~ /at\s+.*\d+/
          s += "\n\tat #{@origin_name}:#{@origin_line}:#{@origin_column}\n"
        end
        s
      else
        @message
      end
    end

    def to_s
      javascript_backtrace
    end

    def message
      to_s
    end
  end

  # Script execution is timed out (see H8::Context#eval timeout parameter)
  class TimeoutError < JsError
    def initialize message
      super
      @message = message
      @source  = nil
    end
  end


end
