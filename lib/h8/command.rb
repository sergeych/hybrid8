$:.unshift File.dirname(__FILE__)
require 'pargser'
require 'ostruct'
require 'h8'

module H8

  class Command

    def initialize *args, out: STDOUT, err: STDERR
      @out = out
      @err = err

      run *args if args.length > 0
    end

    def run *args
      count = 0

      @parser = Pargser.new(args)

      @parser.key('-e', default: false, doc: 'inline coffee code to execute') { |script|
        if script
          @file = '-e'
          context.coffee (@script=script)
          count += 1
        end
      }
          .key('-x', default: nil, doc: 'inline js code to execute') { |script|
        if script
          @file = '-e'
          context.eval (@script=script)
          count += 1
        end
      }

      @parser.parse { |file|
        count   += 1
        @script = open(file, 'r').read
        file.downcase.end_with?('.coffee') and @script = H8::Coffee.compile(@script)
        @file = file
        context.eval @script
      }

      count > 0 or raise 'Must provide at least one file'
    end

    def context
      @context ||= begin
        cxt             = H8::Context.new
        console         = Console.new out: @out, err: @err
        cxt[:console]   = console
        print           = -> (*args) { console.debug *args }
        cxt[:print]     = print
        cxt[:puts]      = print
        cxt[:open]      = -> (name, mode='r', block=nil) { Stream.new(name, mode, block) }
        cxt['__FILE__'] = @file ? @file.to_s : '<inline>'
        cxt[:File] = FileProxy.new
        cxt
      end
    end

    def usage
      "\nh8 #{H8::VERSION} CLI inteface\n\n" +
          "Usage: h8 <file.js/file.coffe>\n\n" +
          @parser.keys_doc
    end

    class FileProxy
      def dirname str
        File.dirname str
      end

      def extname str
        File.extname str
      end

      def basename str
        File.basename str
      end

      def expand_path str
        File.expand_path str
      end

    end

    class Stream
      def initialize name, mode, block=nil
        @file = open(name, mode)
        if block
          block.call self
          @file.close
        end
      end

      def read(count=nil)
        if count
          @file.read(count)
        else
          @file.read
        end
      end

    end

    class Console
      def initialize out: STDOUT, err: STDERR
        @out, @err = out, err
      end

      def debug *args
        @out.puts args.join(' ')
      end

      def log *args
        debug *args
      end

      def error *args
        @err.puts args.join(' ')
      end
    end


  end

end
