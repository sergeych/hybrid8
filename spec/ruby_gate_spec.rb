require 'spec_helper'
require 'h8'

describe 'ruby gate' do

  it 'should gate callables' do
    cxt      = H8::Context.new
    cxt[:fn] = -> (a, b) {
      a + b
    }

    res = cxt.eval "fn(11, 22);"
    res.to_i.should == 33
    cxt = nil
    res = nil
    GC.start
  end

  it 'should pass through ruby objects across js code' do
    class MyObject
      attr :some_val
      def initialize some_val
        @some_val = some_val
      end
    end

    cxt      = H8::Context.new
    cxt[:fn] = -> (a, b) {
      MyObject.new(a+b)
    }

    res = cxt.eval "fn(11, 22);"
    res.should be_kind_of(MyObject)
    res.some_val.should == 33
  end

  it 'should properly pass exceptions via callables' do
    # pending
    class MyException < StandardError; end
    cxt      = H8::Context.new
    cxt[:fn] = -> (a, b) {
      raise MyException, "Shit happens"
    }
    res      = cxt.eval <<-End
        var result = "bad";
        try {
          result = fn(11, 22);
        }
        catch(e) {
          result = { code: 'caught!', exception: e, message: e.message };
        }
        result;
    End
    res.should_not == 'bad'
    # p res.class.name
    # p res
    res.code.should == 'caught!'
    res.message.should == 'ruby exception'
    x = res.exception.source
    x.should be_kind_of(MyException)
    x.message.should == 'Shit happens'
    # res.should be_kind_of(StandardError)
    # It sould be of some reasonable exception class that means gated ruby exception
    # for JS code - be able to retrieve source exception
    # res.should be_kind_of(MyException)
  end

  it 'should object properties'
  it 'should object methods'
  it 'should retain ruby objects'
  it 'should gate classes'
end
