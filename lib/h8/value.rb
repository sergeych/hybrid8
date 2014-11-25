module H8

  # Wrapper for javascript objects.
  #
  # Important: when accessin fields of the object, respond_to? will not work due to
  # js notation, instead, check the returned value to be value.undefined?
  class Value

    include Comparable

    def inspect
      "<H8::Value #{to_s}>"
    end

    # Get js object attribute by its name or index (should be Fixnum instance). It always
    # return H8::Value instance, check it to (not) be undefined? to see if there is such attribute
    def [] name_index
      name_index.is_a?(Fixnum) ? _get_index(name_index) : _get_attr(name_index)
    end

    # Optimized JS member access. Do not yet support calls!
    # use only to get fields
    def method_missing(method_sym, *arguments, &block)
      name = method_sym.to_s
      instance_eval <<-End
              def #{name} *args, **kwargs
                _get_attr('#{name}')
              end
      End
      send method_sym, *arguments
    end

    def each_key
      p eval("Object.keys(this)");
    end

    def <=> other
      other = other.to_ruby if other.is_a?(H8::Value)
      to_ruby <=> other
    end

    def to_ruby
      case
        when integer?
          to_i
        when string?
          to_s
        when float?
          to_f
      end
    end
  end

end
