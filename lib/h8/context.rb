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

    # Execute a given script on the current context
    # @return [Value] wrapped object returned by the script
    def eval script
      # native function. this stub is for documenting only
    end

    # Exectue script in a new context with optionally set vars. @see H8#set_all
    # @return [Value] wrapped object returned by the script
    def self.eval script, ** kwargs
      Context.new(**kwargs).eval script
    end
  end
end
