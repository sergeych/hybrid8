require 'h8/version'
require 'h8/context'
require 'h8/value'
require 'singleton'

module H8
  # The exception that H8 raises on errors
  class Error < StandardError
  end

  class JsError < Error
    attr :message
    attr :source

    def to_s
      message
    end
  end

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
  Undefined = UndefinedClass.instance
end

require 'h8/h8'
