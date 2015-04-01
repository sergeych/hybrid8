require 'spec_helper'
require 'h8'
require 'ostruct'
require 'hashie'

describe 'ruby gate' do

  it 'should gate callables' do
    cxt      = H8::Context.new
    count    = 0
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

  it 'should allow edit context on yield' do
    cxt      = H8::Context.new
    cxt[:fn] = -> (a, b) {
      a + b
    }
    res      = cxt.eval("fn(11, 22);") { |cxt|
      cxt[:fn] = -> (a, b) { a - b }
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

  it 'should convert nil, true, false and undefined' do
    cxt      = H8::Context.new
    value    = false
    cxt[:fn] = -> {
      [nil, true, false, value, H8::Undefined]
    }
    cxt.eval('true').should == true
    cxt.eval('fn();').should == [nil, true, false, false, H8::Undefined]
    cxt.eval('""+fn()[0]').should == 'null'
    # cxt.eval("fn().join(',').toString()").should == ',true,false,false,undefined'
    expect(cxt.eval("(fn()[4] == undefined).toString()")).to eql 'true'
    expect(cxt.eval("(fn()[0] == undefined).toString()")).to eql 'true'
    cxt.eval("(fn()[1])").should == true
    cxt.eval("(fn()[2])").should == false
    cxt.eval("(fn()[3])").should == false
    cxt.eval("(fn()[4])").should == H8::Undefined
    cxt.eval("(fn()[0])").should == nil
    cxt.eval('true').inspect.should == 'true'
    cxt.eval('false').inspect.should == 'false'
  end

  it 'should convert strings to native string' do
    cxt       = H8::Context.new
    cxt[:str] = src = "Пример строки"
    res       = 'ПРИМЕР СТРОКИ'
    cxt.eval('str.toLocaleUpperCase()').should == res
    up = cxt.eval('fn = function(t) { return t.toLocaleUpperCase(); }')
    up.call(src).should == res
  end

  # it 'should convert arrays' do
  #   cxt = H8::Context.new
  #   cxt[:arr] = [1,100,2,200]
  #   p cxt.eval('typeof arr')
  # end

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
      throw Error("It should not happen");
      End
    }).to raise_error(H8::NestedError) { |e|
            e.ruby_error.should be_instance_of(MyException)
            e.ruby_error.message.should == 'Shit happens'
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
      x = e.javascript_error
      e.name.should == 'Error'
      e.message.should =~ /test/
      e.javascript_backtrace.should =~ /at bad \(eval\:4\:17\)/
      e.to_s.should =~ /at bad \(eval\:4\:17\)/
    end
  end

  context 'accessing ruby code' do
    class Base
      def base
        'base called'
      end

      attr_accessor :do_throw
    end

    class Test < Base
      attr :ro, :val
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
      cxt = H8::Context.new
      cxt.eval('RubyGate.prototype.test2 = function() { return "ttt"; }; null;');
      cxt[:foo] = Test.new
      cxt.eval('foo.ro').should == 'readonly'
      cxt.eval('foo.rw').should == 'not initialized'
      cxt.eval('foo.base').should == 'base called'
      cxt.eval('foo.send').should == H8::Undefined
      cxt.eval('foo.freeze').should == H8::Undefined
      cxt.eval('foo.dup').should == H8::Undefined
      cxt.eval('foo.eval').should == H8::Undefined
      cxt.eval('foo.extend').should == H8::Undefined
      cxt.eval('foo.instance_variable_get').should == H8::Undefined
      cxt.eval('foo.object_id').should == H8::Undefined
      cxt.eval('foo.prot_method').should == H8::Undefined
      cxt.eval('foo.priv_method').should == H8::Undefined
      cxt.eval('foo.test_args').should be_kind_of(H8::ProcGate)
      cxt.eval('foo.test_args("hi", "you")').should == 'hi-you'
      cxt.eval('foo instanceof RubyGate').should == true
    end

    context 'do interceptors' do
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
        cxt.eval('foo.base').should == 'base called'
        cxt.eval('foo.send').should == H8::Undefined
        cxt.eval('foo.prot_method').should == H8::Undefined
        cxt.eval('foo.priv_method').should == H8::Undefined
        cxt.eval('foo.test_args').should be_kind_of(H8::ProcGate)
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
      t          = Test.new
      t.do_throw = true
      cxt        = H8::Context.new t: t

      # see Test class implementation: this is a valid test
      cxt.eval("t['foo'];").should == 'init[]'
      cxt.eval("t.foo").should == 'init[]'
      expect(-> { cxt.eval("t['foo1'];") }).to raise_error(H8::NestedError)
      cxt.eval("t.foo='bar'");
      cxt.eval("t.foo;").should == 'bar'
      t.val.should == 'bar'
    end

    it 'should allow adding data to ruby hash' do
      [OpenStruct.new, Hashie::Mash.new].each { |s|
        s.test     = 'foo'
        c          = H8::Context.new
        c[:data]   = s
        c[:assert] = -> (cond) { !cond and raise "assertion failed" }
        c.coffee 'assert data.test == "foo"'
        c.coffee 'data.test = "bar"; assert data.test == "bar"'
        s.test.should == 'bar'
        c.coffee 'data.foo = "baz"'
        s.foo.should == 'baz'
        c.coffee 'data.h = { foo: "bar", bar: { baz: 1 } }'
        c.coffee 'data.bad = "nonono"'
        s.h.foo.should == 'bar'
        s.bad.should == 'nonono'
        c.coffee 'assert data.h.bar.baz == 1'
        c.coffee 'delete data.bad'
        s.h.bar.baz.should == 1
        c.coffee 'data.h.bar.arr = ["hello", { one: 2 }]'
        s.to_ruby.should == { 'test' => "bar", 'foo' => "baz", 'h' => { "foo" => "bar", "bar" => { "baz" => 1, "arr" => ["hello", { "one" => 2 }] } } }
      }
    end

    it 'should delete gated prperties' do
      s = OpenStruct.new 'foo' => 'bar', 'bar' => 'baz'
      s.foo.should == 'bar'
      c = H8::Context.new s: s
      c.eval('s.foo').should == 'bar'
      c.eval 'delete s.foo'
      s.foo.should == nil

      s = Hashie::Mash.new 'foo' => 'bar', 'bar' => 'baz'
      s.foo.should == 'bar'
      c = H8::Context.new s: s
      c.eval('s.foo').should == 'bar'
      c.eval 'delete s.foo'
      s.foo.should == nil

      s = { 'foo' => 'bar', 'bar' => 'baz' }
      c = H8::Context.new s: s
      c.eval('s.foo').should == 'bar'
      c.eval 'delete s.foo'
      s['foo'].should == nil
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
      h       = { 'one' => 2, :two => 21 }
      cxt[:h] = h
      cxt.eval("h['one']").should == 2
      cxt.eval("h['two']").should == 21
      eval("h['one']=1;")
      h['one'].should == 1
    end

    it 'should access ruby and java array functions' do
      begin
        cxt = H8::Context.new
        src = cxt[:h] = [1, 20, 3, 4, 5]
        cxt.eval("h.reverse()").should == [5, 4, 3, 20, 1]
        cxt.eval("h.sort()").should == [1, 3, 4, 5, 20]
        cxt.eval("h.select(function(x){return x >=4;}).sort()").should == [4, 5, 20]
        cxt.eval("h.indexOf(20)").should == 1
        cxt.eval("h.indexOf(21)").should == -1
      rescue H8::NestedError => e
        puts e.ruby_error.backtrace.join("\n")
        raise
      end
    end

    it 'should access ruby string functions' do
      begin
        cxt = H8::Context.new
        src = cxt[:h] = "Hello!"
        cxt.eval("h.indexOf('ll')").should == 2
        cxt.eval("h.indexOf('meow')").should == -1
      rescue H8::NestedError => e
        puts e.ruby_error.backtrace.join("\n")
        raise
      end
    end

    it 'should process to_json' do
      begin
        cxt = H8::Context.new
        src = cxt[:h] = { 'hello' => { 'my' => 'world', 'arr' => [1, 2, 'tre'] } }
        JSON[cxt.eval("JSON.stringify(h)")].should == src
        src = cxt[:h] = [-1, -2, { 'hello' => { 'my' => 'world', 'arr' => [1, 2, 'tre'] } }]
        JSON[cxt.eval("JSON.stringify(h)")].should == src

        src = cxt[:h] = { 'one' => cxt.eval("[ 'hello', { wor: 'ld'} ]") }
        JSON[cxt.eval("JSON.stringify(h)")].should == src
      rescue H8::NestedError => e
        puts e.ruby_error.backtrace.join("\n")
        raise
      end

    end

    it 'should pass varargs' do
      cxt        = H8::Context.new
      cxt[:test] = -> (args) {
        # Sample how to deal with javascript 'arguments' vararg object:
        H8::arguments_to_a(args).join(',')
      }
      res        = cxt.eval <<-End
        function test2() {
          return test(arguments);
        }
        test2(1,2,'ho');
      End
      res.should == '1,2,ho'
    end

    it 'should gate classes through API' do
      c  = H8::Context.new
      la = -> (*args) {
        { 'hello' => 'world' }
      }
      c._gate_class 'Tec', la
      c.eval("var res = new Tec()")
      c.eval('res').should == { 'hello' => 'world' }
      c.eval("res['hello']").should == 'world'
      c.eval('res instanceof Tec').should == true
      c.eval('res instanceof RubyGate').should == true
    end

    class Gated
      attr :init_args

      def initialize *args
        @init_args = args
      end

      def inspect
        "Gated<#{@init_args.inspect}>"
      end

      def checkself
        self
      end

      def checkself2 *args
        self
      end

      def testm a1, a2='???'
        "#{a1} - #{a2}"
      end

      def to_str
        inspect
      end
    end

    it 'should gate classes' do
      cxt = H8::Context.new RClass: Gated
      c   = cxt.eval 'new RClass()'
      c.should be_a(Gated)
      c.init_args.should == []

      c = cxt.eval 'rc = new RClass("hello", "world")'
      c.should be_a(Gated)
      cxt.eval('rc instanceof RubyGate').should == true
      cxt.eval('new RClass() instanceof RClass').should == true
      c.init_args.should == ['hello', 'world']
      cxt.eval('rc.init_args').should == ['hello', 'world']
    end

    it 'should provide apply to gated class and instance' do
      c = H8::Context.new RClass: Gated
      c.eval('new RClass().testm(1,"d");').should == '1 - d'
      c.eval('new RClass().testm.apply( null, [1,"n"]);').should == '1 - n'
    end

    it 'should not die on calling wrong arity' do
      cxt = H8::Context.new RClass: Gated
      g1  = cxt.eval 'var g1 = new RClass(1,2.3); g1'

      # We call gated ruby object with wrong number of args
      # which in turn causes attempt to call not callable result:
      expect(-> { cxt.eval('g1.checkself(12)') }).to raise_error(H8::NestedError) { |e|
                                                       e.ruby_error.should be_instance_of(NoMethodError)
                                                     }
    end

    it 'should return self from gated class' do
      cxt = H8::Context.new RClass: Gated
      g1  = cxt.eval 'var g1 = new RClass(1,2.3); g1'
      g1.should be_a(Gated)
      g2 = cxt.eval 'g1.checkself'
      g2.should be_a(Gated)
      g1.equal?(g2).should == true
      cxt.eval('g1 instanceof RClass').should == true
      # p cxt.eval('g1.checkself.toString()')
      cxt.eval('g1.checkself instanceof RClass').should == true
      cxt.eval('g1.checkself === g1').should == true

      # This checks how id map works (lite check)
      cxt.eval('g1.checkself2(1) instanceof RClass').should == true
      cxt.eval('g1.checkself2(2) === g1').should == true
    end

    it 'should expendable gate classes' do
      cxt = H8::Context.new RClass: Gated
      expect(-> { cxt.eval 'new RClass().mm(1)' }).to raise_error(H8::JsError)
      cxt.eval('RClass.prototype.mm = function(a) { return "bar" + a; };')
      cxt.eval('var x = new RClass(11); x.mm("hi!");').should == 'barhi!';
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
