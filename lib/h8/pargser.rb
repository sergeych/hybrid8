require 'set'

module H8
  class Pargser

    class Error < ArgumentError; end

    # Create parser instance with a list of arguments. Otherwise, arguments can
    # be passed to #parse call.
    #
    # @param [Array] args arguments
    def initialize args=[]
      @args     = args
      @keys     = {}
      @required = Set.new
      @docs     = []
    end

    # Register key handler.
    # When #parse handler blocks will be called in order of appearance in
    # arguments array
    #
    #
    # @param [String] name key name
    #
    # @param [Array(String)] aliases for the key
    #
    # @param [Boolean] :needs_value if set then the parser wants a value argument after the
    #   key which will be passed to block as an argument. if default param is not set and
    #   the key will not be detected, Pargser::Error will be raised
    #
    # @param [String] :default value. if set, needs_value parameter can be omitted - the handler
    #   block will be passed either with this value or with one specified in args.
    #
    # @param [String] :doc optional documentation string that will be used in #keys_doc
    #
    # @yield block if the key is found with optional value argument
    #
    def key name, *aliases, needs_value: false, doc: nil, **kwargs, &block
      k = name.to_s

      default_set = false
      default = nil
      if kwargs.include?(:default)
        default = kwargs[:default]
        needs_value = true
        default_set = true
      end

      @keys.include?(k) and raise Error, "Duplicate key registration #{k}"
      data = @keys[k] = OpenStruct.new required:    false,
                                       needs_value: needs_value,
                                       block:       block,
                                       doc:         doc,
                                       key:         k,
                                       aliases:     aliases,
                                       default:     default,
                                       default_set: default_set
      @docs << data
      aliases.each { |a| @keys[a.to_s] = data }
      @required.add(data) if needs_value
      self
    end

    # Process command line and call key handlers in the order of
    # appearance. Then call handlers that keys which need values
    # and were not called and have defaults, or raise error.
    #
    # The rest of arguments (non-keys) are either yielded or returned
    # as an array.
    #
    # You can optionally set other arguments than specified in constructor
    #
    # @param [Array] args to parse. If specified, arguments passed to constructor
    #                will be ignored and lost
    # @return [Array] non-keys arguments (keys afer '--' or other arguments)
    # @yield [String] non keys argumenrs (same as returned)
    def parse args=nil
      @args = args if args
      no_more_keys = false
      rest         = []
      while !@args.empty?
        a = @args.shift
        case
          when no_more_keys
            rest << a
          when (data = @keys[a])
            @required.delete data
            if data.needs_value
              value = @args.shift or raise "Value needed for key #{a}"
              data.block.call value
            else
              data.block.call
            end
          when a == '--'
            no_more_keys = true
          when a[0] == '-'
            raise Error, "Unknown key #{a}"
          else
            rest << a
        end
      end
      @required.each { |data|
        raise Error, "Required key is missing: #{data.key}" if !data.default_set
        data.block.call data.default
      }
      block_given? and rest.each { |a| yield a }
      rest
    end

    # Generate keys documentation multiline text
    def keys_doc
      res = []
      @docs.each { |d|
        keys = [d.key] + d.aliases
        str = "\t#{keys.join(',')}"
        if d.needs_value
          str += " value"
          if d.default
            str += " (default: #{d.default})" if d.default
          else
            str += ' (optional)'
          end
        end
        res << str
        d.doc and d.doc.split("\n").each{ |l| res << "\t\t#{l}" }
      }
      res.join("\n")
    end

  end

end
