require 'thread'

module H8
  class Context
    # Create new context optionally providing variables hash
    def initialize **kwargs
      @idcount = 0
      set_all **kwargs
      _set_var '___create_ruby_class', -> (cls, args) {
        _do_cretate_ruby_class cls, args
      }
    end

    # set variables from keyword arguments to this context
    # see #[]= for details
    def set_all **kwargs
      kwargs.each { |name, value|
        set_var(name.to_s, value)
      }
    end

    # Set variable/class for the context. It can set variable to hold:
    #  * primitive type (like string, integer, nil, float and like) - by value!
    #  * any other ruby object - by reference
    #  * ruby Class - creating a javascript constructor function that creates ruby
    #    class instance (any arguments) and gates it to use with js.
    def []= name, value
      set_all name => value
    end

    # Execute a given script on the current context with optionally limited execution time.
    #
    # @param [Int] timeout if is not 0 then maximum execution time in millis (therubyracer
    #              compatibility)
    # @param [Float] max_time if is not 0 then maximum execution time in seconds. Has precedence
    #                over timeout
    #
    # @return [Value] wrapped object returned by the script
    # @raise [H8::TimeoutError] if the timeout was set and expired
    def eval script, max_time: 0, timeout: 0
      timeout = max_time * 1000 if max_time > 0
      yield(self) if block_given?
      _eval script, timeout.to_i
    end

    # Execute script in a new context with optionally set vars. @see H8#set_all
    # @return [Value] wrapped object returned by the script
    def self.eval script, **kwargs
      Context.new(** kwargs).eval script
    end

    # Secure gate for JS to securely access ruby class properties (methods with no args)
    # and methods. This class implements security policy! Overriding this method could
    # breach security and provide full access to ruby object trees.
    #
    # It has very complex logic so the security model update should be done somehow
    # else.
    def self.secure_call instance, method, args=nil
      method = method.to_sym
      begin
        m = instance.public_method(method)
        if m.owner == instance.class
          return m.call(*args) if method[0] == '[' || method[-1] == '='
          if m.arity != 0
            return -> (*args) { m.call *args }
          else
            return m.call *args
          end
        end
      rescue NameError
        # No exact method, calling []/[]= if any
        method, args = if method[-1] == '='
                         [:[]=, [method[0..-2].to_s, args[0]] ]
                       else
                         [:[], [method.to_s]]
                       end
        begin
          m = instance.public_method(method)
          if m.owner == instance.class
            return m.call(*args)
          end
        rescue NameError
          # It means there is no [] or []=, e.g. undefined
        end
      end
      H8::Undefined
    end

    protected

    # Set var that could be either a callable, class instance, simple value or a Class class
    # in which case constructor function will be created
    def set_var name, value
      if value.is_a?(Class)
        clsid = "__ruby_class_#{@idcount += 1}"
        _set_var clsid, value
        eval <<-End
          function #{name.to_s}() {
            return ___create_ruby_class(#{clsid}, arguments);
          }
        End
      else
        _set_var name, value
      end
    end

    # create class instance passing it arguments stored in javascript 'arguments' object
    # (so it repacks them first)
    def _do_cretate_ruby_class(klass, arguments)
      klass.new *H8::arguments_to_a(arguments.to_ruby.values)
    end
  end

  # class RacerContext < Context
  #   protected
  #   def set_var name, value
  #     if value.is_a?(Proc)
  #       n1 = "___compat_#{name}"
  #       _eval "function #{name}() { return #{n1}( this, arguments); }", 0
  #       super n1, -> (this, arguments) {
  #         args = [this] + H8::arguments_to_a(arguments)
  #         value.call *args
  #       }
  #     else
  #       super name, value
  #     end
  #   end
  # end

end
