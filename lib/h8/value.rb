require 'ostruct'

module H8

  # Wrapper for javascript objects.
  #
  # Important: when accessing fields of the object, respond_to? will not work due to
  # js notation, instead, check the returned value (there will be always one) to not to be
  # value.undefined?
  #
  # Precaution! Values are always bounded to the context where they are created. You can not
  # pass values between context, as they often map native Javascript objects. If you need, you
  # can copy, for example, by converting it H8::Value#to_ruby first. Another approach is to
  # use JSON serialization from the script.
  #
  # Interesting thing about H8::Value is that when passed back to some javascript environment
  # (say, callback parameted or as a global variable), it unwraps source javascript object -
  # no copying, no modifying.
  class Value

    include Comparable

    def inspect
      "<H8::Value #{to_ruby rescue '(too deep)'}>"
    end

    # Get js object attribute by either name or index (should be Fixnum instance). It always
    # return H8::Value instance, check it to (not) be undefined? to see if there is such attribute
    #
    # @return [H8::Value] instance, which is .undefined? if does not exist
    def [] name_index
      name_index.is_a?(Fixnum) ? _get_index(name_index) : _get_attr(name_index.to_s)
    end

    # Set js object attribute by either name or index (should be Fixnum instance).
    def []= name_index, value
      # name_index.is_a?(Fixnum) ? _get_index(name_index) : _get_attr(name_index.to_s)
      _set_attr(name_index.to_s, value)
    end

    # Optimizing JS member access. Support class members and member functions - will call them
    # automatically. Use val['attr'] to get callable instead.
    #
    # First invocation creates accessor method so future calls happen much faster
    def method_missing(method_sym, *arguments, &block)
      name = method_sym.to_s
      if name[-1] != '='
        instance_eval <<-End
                def #{name} *args, **kwargs
                  res = _get_attr('#{name}')
                  (res.is_a?(H8::Value) && res.function?) ? res.apply(self,*args) : res
                end
        End
      else
        instance_eval <<-End
                def #{name} value
                  _set_attr('#{name[0..-2]}', value)
                end
        End
      end
      send method_sym, *arguments
    end

    # Compare to other object, either usual or another Value instance. Tries its best.
    # be sure to use it wisely and report any problems
    def <=> other
      other = other.to_ruby if other.is_a?(H8::Value)
      to_ruby <=> other
    end

    # Call javascript function represented by this instance (which should be function())
    # with given (or no) arguments.
    # @return [H8::Value] function return which might be undefined
    def call *args
      _call args
    end

    # Like JS apply: call the value that should be function() bounded to a given object
    # @param [Object] this object to bound call to
    # @param args any arguments
    # @return [H8::Value] result returned by the function which might be undefined
    def apply this, *args
      _apply this, args
    end

    # Tries to convert JS object to ruby array
    # @raise H8::Error if the JS object is not an array
    def to_ary
      raise Error, 'Is not an array' unless array?
      to_ruby
    end

    alias :to_a :to_ary

    # Generate set of keys of the wrapped object
    def keys
      context[:__obj] = self
      Set.new context.eval("(Object.keys(__obj));").to_a
    end

    # enumerate |key, value| pairs for javascript object attributes
    def each
      return enum_for(:each) unless block_given? # Sparkling magic!
      keys.each { |k|
        yield k, _get_attr(k)
      }
    end

    # Try to convert javascript object to a ruby hash
    def to_h depth=0
      each.reduce({}) { |all, kv| all[kv[0]] = kv[1].to_ruby depth; all }
    end

    # Iterate over javascript object keys
    def each_key
      keys.each
    end

    # @return [Array] values array. does NOT convert values to_ruby()
    def values
      each.reduce([]) { |all, kv| all << kv[1]; all }
    end

    # iterate over values of the javascript object attributes
    def each_value
      values.each
    end

    # Tries to convert wrapped JS object to ruby primitive (Fixed, String, Float, Array, Hash).
    # Note that this conversion looses information about source javascript class (if any).
    #
    # @raise H8::Error if the data structure is too deep (e.g. cyclic)
    def to_ruby depth=0
      depth += 1
      raise H8::Error, "object tree too deep" if depth > 100
      case
        when integer?
          to_i
        when string?
          to_s
        when float?
          to_f
        when array?
          _get_attr('length').to_i.times.map { |i| _get_index(i).to_ruby depth }
        when function?
          to_proc
        when object?
          to_h depth
        else
          raise Error, "Dont know how to convert #{self.class}"
      end
    end

    def function? # native method. stub for documentation
    end

    def object? # native method. stub for documentation
    end

    def undefined? # native method. stub for documentation
    end

    def array? # native method. stub for documentation
    end

    # @return [H8::Context] context to which this value is bounded
    def context # native method. stub for documentation
    end

    # Convert to Proc instance so it could be used as &block parameter
    # @raises (H8::Error) if !self.function?
    def to_proc
      function? or raise H8::Error, 'JS object is not a function'
      -> (*args) { call *args }
    end

    def to_str
      to_s
    end
  end

end

class OpenStruct
  # OpenStruct converts to plain ruby hash in depth. Primary usage
  # is when it was used bu javascript and could contain gated objects.
  def to_ruby depth=0
    to_h.to_ruby depth+1
  end
end

class Hash
  # Hash copies in depth converting its data. Primary usage
  # is when it was used bu javascript and could contain gated objects.
  #
  # Important! that converted keys are turned to string even of were
  # pure ruby symbols. This is done to remove ambiguity: work the same
  # with ruby hashes, javasctipt objects, OpenStruct and Hashie::Mash instances
  def to_ruby depth=0
    res = {}
    depth += 1
    each { |k,v| res[k.to_ruby(depth).to_s] = v.to_ruby depth }
    res
  end
end

class Array
  # @return new array with all components converted to_ruby
  def to_ruby depth
    depth += 1
    map { |x| x.to_ruby depth }
  end
end

# Ruby object's t_ruby does nothing (tree conversion optimization)
class Object
  # It is already a ruby object. Gate objects should override
  # as need
  def to_ruby depth=0
    self
  end
end

