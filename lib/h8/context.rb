require 'thread'
require 'h8'
require 'json'

class Array
  def _select_js callable
    select { |item|
      callable.call item
    }
  end

  def indexOf item
    index(item) || -1
  end
end

class String
  def indexOf item
    index(item) || -1
  end
end

class Object
  def __to_json
    if respond_to?(:as_json)
      as_json
    else
      JSON[JSON[self]]
    end
  end
end

module H8

  class Context
    # Create new context optionally providing variables hash
    def initialize noglobals: false, **kwargs
      @idcount = 0
      set_all **kwargs
      _set_var '___create_ruby_class', -> (cls, args) {
        _do_create_ruby_class cls, args
      }

      self[:debug] = -> (*args) {
        puts args.join(' ')
      }

      noglobals or execute_script 'globals.coffee'
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
      set_all name.to_sym => value
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
    def eval script, max_time: 0, timeout: 0, file_name: nil
      timeout = max_time * 1000 if max_time > 0
      yield(self) if block_given?
      _eval script, timeout.to_i, file_name
    end

    # Compile and execute coffeescript, taking same arguments as #eval.
    #
    # If you need to execute same script more than once consider first H8::Coffee.compile
    # and cache compiled script.
    def coffee script, ** kwargs
      eval Coffee.compile script, ** kwargs
    end


    # Execute script in a new context with optionally set vars. @see H8#set_all
    # @return [Value] wrapped object returned by the script
    def self.eval script, file_name: nil, ** kwargs
      Context.new(** kwargs).eval script, file_name: file_name
    end

    # Secure gate for JS to securely access ruby class properties (methods with no args)
    # and methods. This class implements security policy. Overriding this method could
    # breach security and provide full access to ruby object trees.
    #
    # It has very complex logic so the security model update should be done somehow
    # else.
    def self.secure_call instance, method, args=nil
      # p [:sc, instance, method, args]
      if instance.is_a?(Array)
        method == 'select' and method = '_select_js'
      end
      method = method.to_sym
      begin
        m     = instance.public_method(method)
        owner = m.owner
        if can_access?(owner)
          return m.call(*args) if method[0] == '[' || method[-1] == '='
          if m.arity != 0
            return ProcGate.new( -> (*args) { m.call *args } )
          else
            return m.call
          end
        end
      rescue NameError
        # No exact method, calling []/[]= if any
        method, args = if method[-1] == '='
                         [:[]=, [method[0..-2].to_s, args[0]]]
                       else
                         [:[], [method.to_s]]
                       end
        begin
          m = instance.public_method(method)
          if can_access?(owner)
            if method == :[]
              if instance.is_a?(Hash)
                return m.call(*args) || m.call(args[0].to_sym)
              else
                return m.call(*args)
              end
            else
              return m.call(*args)
            end
          end
        rescue NameError
          # It means there is no [] or []=, e.g. undefined
        end
      end
      H8::Undefined
    end

    # This is workaround for buggy rb_proc_call which produces segfaults
    # if proc is not exactly a proc, so we call it like this:
    def safe_proc_call proc, args
      if proc.respond_to?(:call)
        proc.call(*args)
      else
        if args.length == 0
          proc # Popular bug: call no-arg method not like a property
        else
          raise NoMethodError, "Invalid callable"
        end
      end
      # proc.is_a?(Array) ? proc : proc.call(*args)
    end

    # :nodoc:
    # Internal handler to properly delete fields/keys from ruby Hashes or
    # OpenStruct
    #
    def self.delete_handler object, args
      name = args[0]
      if object.is_a?(OpenStruct)
        object.delete_field name
      else
        object.delete name
      end
    end

    def self.can_access?(owner)
      return true if owner.is_a?(Array.class)
      owner != Object.class && owner != Kernel && owner != BasicObject.class
    end

    protected

    # Set var that could be either a callable, class instance, simple value or a Class class
    # in which case constructor function will be created
    def set_var name, value
      case value
        when Class
          _gate_class name.to_s, -> (*args) { value.new *args }
        when Proc
          _set_var name, ProcGate.new(value)
        else
          _set_var name, value
      end
    end

    # create class instance passing it arguments stored in javascript 'arguments' object
    # (so it repacks them first)
    def _do_create_ruby_class(klass, arguments)
      klass.new *H8::arguments_to_a(arguments.to_ruby.values)
    end


    @@base  = File.expand_path File.join(File.dirname(__FILE__), '../scripts')
    @@cache = {}

    def execute_script name
      # p [:exs, name]
      script = @@cache[name] ||= begin
        # p 'cache miss'
        script = open(File.join(@@base, name), 'r').read
        name.downcase.end_with?('.coffee') ? H8::Coffee.compile(script) : script
      end
      eval script
    end

  end

  # The gate for Ruby's callable to support javascript's 'apply' functionality
  class ProcGate
    def initialize callable
      @callable = callable
    end

    def apply this, args
      @callable.call *args
    end

    def call *args
      @callable.call *args
    end
  end

end
