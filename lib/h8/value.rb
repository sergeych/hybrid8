module H8

  class Value
    def inspect
      "<H8::Value #{to_s}>"
    end

    def [] name
      return get_attr(name)
    end

    def respond_to? method_sym, include_private = false
      res = get_attr(method_sym.to_s)
      if res.undefined?
        super
      else
        true
      end
    end

    def method_missing(method_sym, *arguments, &block)
      res = get_attr(method_sym.to_s)
      if res.undefined?
        super
      else
        res
      end
    end
  end

end
