module H8

  # Wrapper for javascript objects.
  #
  # Important: when accessin fields of the object, respond_to? will not work due to
  # js notation, instead, check the returned value to be value.undefined?
  class Value
    def inspect
      "<H8::Value #{to_s}>"
    end

    # Get js object attribute by its name or index (should be Fixnum instance). It always
    # return H8::Value instance, check it to (not) be undefined? to see if there is such attribute
    def [] name_index
      name_index.is_a?(Fixnum) ? get_index(name_index) : get_attr(name_index)
    end

    # Optimized JS member access. Do not yet support calls!
    # use only to get fields
    def method_missing(method_sym, *arguments, &block)
      name = method_sym.to_s
      instance_eval <<-End
              def #{name} *args, **kwargs
                get_attr('#{name}')
              end
      End
      send method_sym, *arguments
    end
  end

end
