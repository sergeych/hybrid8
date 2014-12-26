require 'h8/version'
require 'h8/context'
require 'h8/value'
require 'singleton'

module H8
  # The exception that H8 raises on errors that are not caused by executing
  # javascript (e.g. bad parameters, illegal conversion and so on)
  class Error < StandardError
  end

  # The general error caused by the script execution, e.g. uncaught javascript exceptinos and like.
  # Check #message to see the cause.
  class JsError < Error
    attr :message
    attr :source

    def to_s
      message
    end
  end

  # Script execution is timed out (see H8::Context#eval timeout parameter)
  class TimeoutError < JsError
    def initialize message
      super
      @message = message
      @source = nil
    end
  end

  # The class representing undefined in javascript. Singleton
  # Nota that H8::Undefined == false but is not FalseClass
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
end

require 'h8/h8'
