module H8
  class Context
    def initialize timout: nil, **kwargs
      set **kwargs
    end

    def set **kwargs
      kwargs.each { |name, value|
        set_var(name.to_s, value)
      }
    end

    def []= name, value
      set name => value
    end

    def self.eval script
      Context.new.eval script
    end
  end
end
