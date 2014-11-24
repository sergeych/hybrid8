module H8

  class Value
    def inspect
      "<H8::Value #{to_s}>"
    end

    def [] name
      return get_attr(name)
    end

  end

end
