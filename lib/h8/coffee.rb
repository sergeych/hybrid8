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
        (@@compiler ||= Coffee.new).eval src, **kwargs
      }
    end

    # Compile coffeescript and return javascript. Keyword parameters are
    # passed to H8::Context#eval - like time limits and so on.
    #
    # This method IS THREAD SAFE, though it shares single
    # compiler instance across all threads with a mutex.
    def self.compile src, ** kwargs
      @@mutex.synchronize {
        (@@compiler ||= Coffee.new).compile src, **kwargs
      }
    end

    # Create compiler instance.
    def initialize
      @context = H8::Context.new noglobals: true
      @context.eval read_script 'coffee-script.js'
      eval read_script('globals.coffee')
    end

    # compile coffeescript source and return compiled javascript
    def compile src, file_name: nil, **kwargs
      @context[:cs] = src
      @context[:filename] = file_name
      res = @context.eval('CoffeeScript.compile(cs,{filename: filename})')
      @context[:cs] = nil # Sources can be big...
      res
    end

    # Compile and evaulate coffee script. Optional parameters are passed
    # to H8::Context#eval
    def eval src, **kwargs
      @context.eval compile(src), **kwargs
    end

    # Provide context with CoffeeScrip compiler loaded
    def context
      @context
    end

    private

    @@base = File.expand_path File.join(File.dirname(__FILE__), '../scripts')
    @@cache = {}

    def read_script name
      @@cache[name] ||= open(File.join(@@base, name), 'r').read
    end
  end

end
