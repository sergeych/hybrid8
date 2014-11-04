module H8
  class Context
    def initialize timout: nil
    end

    def self.eval script
      Context.new.eval script
    end
  end
end
