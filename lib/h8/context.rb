module H8
  class Context
    # Create new context optionally providing variables hash
    def initialize timout: nil, **kwargs
      set_all **kwargs
    end

    # set variables from keyword arguments to this context
    def set_all **kwargs
      kwargs.each { |name, value|
        set_var(name.to_s, value)
      }
    end

    # Set variable for the context
    def []= name, value
      set_all name => value
    end

    # Execute a given script on the current context with optionally limited execution time.
    #
    # @param [Float] timeout if is not 0 then maximum execution time in seconds
    # @return [Value] wrapped object returned by the script
    # @raise [H8::TimeoutError] if the timeout was set and expired
    def eval script, timeout: 0
      _eval script, (timeout*1000).to_i
    end

    # Execute script in a new context with optionally set vars. @see H8#set_all
    # @return [Value] wrapped object returned by the script
    def self.eval script, **kwargs
      Context.new(** kwargs).eval script
    end

    # Secure gate for JS to securely access ruby class properties (methods with no args)
    # and methods.
    def self.secure_call instance, method, args=nil
      method = method.to_sym
      begin
        m = instance.public_method(method)
        if m.owner == instance.class
          return m.call(*args) if method[-1] == '='
          if m.arity != 0
            return -> (*args) { m.call *args }
          else
            return m.call *args
          end
        end
      rescue NameError
      end
      H8::Undefined
    end
  end
end
