require 'json'
require 'thread'

module H8

  # Coffeescript compiler and evaluator (language version 1.8.0)
  #
  # Note that using global eval/compile is more efficient than create several
  # compiler instance as compiler itself will then be compiled only once.
  class Coffee

    @@compiler = nil
    @@mutex = Mutex.new

    # Compile and evaluate script.
    #
    # This method IS THREAD SAFE, it shares single
    # compiler instance across all threads with a mutex.
    def self.eval src, ** kwargs
      @@mutex.synchronize {
        (@@compiler ||= Coffee.new).eval src, ** kwargs
      }
    end

    # Compile coffeescript and return javascript. Keyword parameters are
    # passed to H8::Context#eval - like time limits and so on.
    #
    # This method IS THREAD SAFE, it shares single
    # compiler instance across all threads with a mutex.
    def self.compile src, ** kwargs
      @@mutex.synchronize {
        (@@compiler ||= Coffee.new).compile src, ** kwargs
      }
    end

    # Create compiler instance.
    def initialize
      @context = H8::Context.new
      @context.eval open(File.join(File.dirname(File.expand_path(__FILE__)),'/coffee-script.js'), 'r').read
    end

    # compile coffeescript source and return compiled javascript
    def compile src, **kwargs
      @context[:cs] = src
      res = @context.eval('CoffeeScript.compile(cs)')
      @context[:cs] = nil # Sources can be big...
      res
    end

    # Compile and evaulate coffee script. Optional parameters are passed
    # to H8::Context#eval
    def eval src, **kwargs
      @context.eval compile(src), **kwargs
    end
  end


end
