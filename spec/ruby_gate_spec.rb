require 'spec_helper'
require 'h8'

describe 'ruby gate' do

  it 'should gate callables' do
    cxt      = H8::Context.new
    count = 0
    cxt[:fn] = -> (a, b) {
      count += 1
      a + b
    }

    res = cxt.eval "fn(11, 22);"
    res.to_i.should == 33
    cxt = nil
    res = nil
    GC.start
    count.should == 1
  end

  # it 'should gate callables in therubyrace mode' do
  #   cxt      = H8::Context.new
  #   cxt[:fn] = -> (this, a, b) {
  #     p this.to_s
  #     p this.offset
  #     this.offset + a + b
  #   }
  #
  #   res = cxt.eval <<-End
  #     function Test() {
  #       this.offset = 110;
  #       this.method = function(a,b) {
  #         return fn(this,a,b);
  #       }
  #     }
  #     new Test().method(11, 22);
  #   End
  #   res.to_i.should == 143
  # end

  it 'should allow edit context on yield' do
    cxt      = H8::Context.new
    cxt[:fn] = -> (a, b) {
      a + b
    }
    res = cxt.eval("fn(11, 22);") { |cxt|
      cxt[:fn] = -> (a,b) { a - b }
    }
    res.to_i.should == -11
  end

  it 'va: should gate callables with varargs' do
    cxt      = H8::Context.new
    cxt[:fn] = -> (*args) {
      args.reduce(0) { |all, x| all+x }
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

  it 'should have information about javascript exceptions' do
    # javascript_backtrace - list of strings?
    begin
      H8::Context.eval <<-End
        // This is ok
        var ok = true;
        function bad() {
          throw Error("test");
        }
        function good() {
          bad();
        }
        // This is also ok
        good();
      End
      fail 'did not raise error'
    rescue H8::JsError => e
      x  = e.javascript_error
      e.name.should == 'Error'
      e.message.should =~ /test/
      e.javascript_backtrace.should =~ /at bad \(eval\:4\:17\)/
      e.to_s.should =~ /at bad \(eval\:4\:17\)/
    end
  end

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
        @ro           = 'readonly'
        @rw           = 'not initialized'
        @val          = 'init[]'
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

    context 'no interceptors' do
      class Test2 < Base
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
        cxt[:foo] = Test2.new
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
        cxt[:foo] = t = Test2.new
        cxt.eval('foo.rw="hello";')
        t.rw.should == 'hello'
        cxt.eval('foo.rw').should == 'hello'
      end
    end

    it 'should add and intercept property access' do
      # pending
      t          = Test.new
      t.do_throw = true
      cxt        = H8::Context.new t: t
      cxt.eval("t['foo'];").should == 'init[]'
      expect(-> { cxt.eval("t['foo1'];") }).to raise_error(RuntimeError)
      cxt.eval("t['foo']='bar'");
      # p t['foo']
      # p cxt.eval "t['foo'] = 'bar';"
    end

    it 'should access plain arrays (provide numeric indexes)' do
      cxt     = H8::Context.new
      array   = [10, 20, 30]
      cxt[:a] = array
      cxt.eval('a.length').should == 3
      cxt.eval('a[1]').should == 20
      cxt.eval('a[0] = 100; a[0]').should == 100
      array[0].should == 100
    end

    it 'should access plain hashes' do
      cxt     = H8::Context.new
      h       = { 'one' => 2 }
      cxt[:h] = h
      cxt.eval("h['one']").should == 2
      eval("h['one']=1;")
      h['one'].should == 1
    end

    it 'should pass varargs' do
      cxt = H8::Context.new
      cxt[:test] = -> (args) {
        # Sample how to deal with javascript 'arguments' vararg object:
        H8::arguments_to_a(args).join(',')
      }
      res = cxt.eval <<-End
        function test2() {
          return test(arguments);
        }
        test2(1,2,'ho');
      End
      res.should == '1,2,ho'
    end

    it 'should gate classes' do
      class Gated
        attr :init_args

        def initialize *args
          @init_args = args
        end
      end

      cxt = H8::Context.new RClass: Gated
      c = cxt.eval 'new RClass()'
      c.should be_a(Gated)
      c.init_args.should == []

      c = cxt.eval 'rc = new RClass("hello", "world")'
      c.should be_a(Gated)
      c.init_args.should == ['hello', 'world']
      cxt.eval('rc.init_args').should == ['hello', 'world']
    end
  end

  it 'should survive recursive constructions' do
    a = H8::Context.eval 'a=[1,2]; a.push(a); a'
    expect(-> { a.to_ruby }).to raise_error(H8::Error)
    a = H8::Context.eval "a={on:2}; a['a']=a; a"
    expect(-> { a.to_ruby }).to raise_error(H8::Error)
    a.inspect.should =~ /too deep/
  end
end
