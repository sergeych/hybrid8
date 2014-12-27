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
      args.reduce(0){|all,x| all+x }
    }

    cxt.eval('fn(11, 22, 100);').should == 133
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

      attr_accessor :do_throw
    end

    class Test < Base
      attr :ro
      attr_accessor :rw

      def initialize
        @ro = 'readonly'
        @rw = 'not initialized'
        @val = 'init[]'
        self.do_throw = false
      end

      def test_args *args
        args.join('-')
      end

      def [] val
        if val != 'foo'
          raise('not foo') if do_throw
          H8::Undefined
        else
          @val
        end
      end

      def []= val, x
        val != 'foo' && do_throw and raise "not foo"
        @val = x
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

    it 'should access index methods'

    it 'should add and access indexed attributes' do
      # pending
      t = Test.new
      t.do_throw = true
      cxt = H8::Context.new t: t
      cxt.eval("t['foo'];").should == 'init[]'
      expect(->{cxt.eval("t['foo1'];")}).to raise_error(RuntimeError)
      cxt.eval("t['foo']='bar'");
      # p t['foo']
      # p cxt.eval "t['foo'] = 'bar';"
    end

    it 'should access plain arrays (provide numeric indexes)' do
      cxt   = H8::Context.new
      array = [10, 20, 30]
      cxt[:a] = array
      cxt.eval('a.length').should == 3
      cxt.eval('a[1]').should == 20
      cxt.eval('a[0] = 100; a[0]').should == 100
      array[0].should == 100
    end

    it 'should access plain hashes' do
      cxt   = H8::Context.new
      h = {'one' => 2 }
      cxt[:h] = h
      cxt.eval("h['one']").should == 2
      eval("h['one']=1;")
      h['one'].should == 1
    end

    it 'should allow adding poroperties to ruby objects'


    it 'should gate classes'
  end

  it 'should retain ruby objects'
end
