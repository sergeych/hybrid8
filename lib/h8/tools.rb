require 'singleton'

module H8
  # The class representing undefined in javascript. Singleton
  # Note that H8::Undefined == false but is not FalseClass
  class UndefinedClass
    include Singleton

    def blank?
      true
    end

    def undefined?
      true
    end

    def empty?
      true
    end

    def present?
      false
    end

    def !
      true
    end

    def == x
      x.is_a?(H8::UndefinedClass) || x == false
    end
  end

  # The constant representing 'undefined' value in Javascript
  # The proper use is to compare returned value res == H8::Undefined
  Undefined = UndefinedClass.instance


  # Convert javascript 'arguments' object to ruby array
  def arguments_to_a args
    res = Array.new(l=args.length)
    l.times { |n| res[n] = args[n] }
    res
  end

  module_function :arguments_to_a
end

