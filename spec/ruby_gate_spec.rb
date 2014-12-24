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

  it 'should gate callables with varargs' do
    cxt      = H8::Context.new
    cxt[:fn] = -> (*args) {
      p args.join(' ')
    }

    res = cxt.eval "fn(11, 22);"
    GC.start
  end

  it 'should convert nil' do
    cxt      = H8::Context.new
    cxt[:fn] = -> {
      nil
    }
    cxt.eval('fn();').should == nil
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
    class MyException < StandardError;
    end
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
    res.code.should == 'caught!'
    res.message.should == 'ruby exception'
    x = res.exception.source
    x.should be_kind_of(MyException)
    x.message.should == 'Shit happens'
  end

  it 'should pass through uncaught ruby exceptions' do
    class MyException < StandardError;
    end
    cxt      = H8::Context.new
    # pending
    cxt[:fn] = -> (a, b) {
      raise MyException, "Shit happens"
    }
    expect(-> {
      res = cxt.eval <<-End
      result = fn(11, 22);
      End
    }).to raise_error(MyException) { |e|
            e.message.should == 'Shit happens'
          }
  end

  it 'should have information about javascript exceptions'

  context 'accessing ruby code' do
    class Base
      def base
        raise "It should not be called"
      end
    end

    class Test < Base
      attr :ro
      attr_accessor :rw

      def initialize
        @ro = 'readonly'
        @rw = 'not initialized'
      end

      def test_args *args
        args.join('-')
      end

      protected

      def prot_method
        raise 'should not be called'
      end

      private

      def priv_method
        raise 'should not be called'
      end

    end

    it 'should access object properties and methods' do
      cxt       = H8::Context.new
      cxt[:foo] = Test.new
      cxt.eval('foo.ro').should == 'readonly'
      cxt.eval('foo.rw').should == 'not initialized'
      cxt.eval('foo.base').should == H8::Undefined
      cxt.eval('foo.send').should == H8::Undefined
      cxt.eval('foo.prot_method').should == H8::Undefined
      cxt.eval('foo.priv_method').should == H8::Undefined
      cxt.eval('foo.test_args').should be_kind_of(Proc)
      cxt.eval('foo.test_args("hi", "you")').should == 'hi-you'
    end

    it 'should set ruby properties' do
      cxt       = H8::Context.new
      cxt[:foo] = t = Test.new
      cxt.eval('foo.rw="hello";')
      t.rw.should == 'hello'
      cxt.eval('foo.rw').should == 'hello'
    end

    it 'should gate classes'
  end

  it 'should retain ruby objects'
end
