require 'spec_helper'
require 'h8'
require 'weakref'

describe 'js_gate' do

  it 'should return number as string' do
    cxt = H8::Context.new
    res = cxt.eval("0.2 + 122.1;")
    res.to_s.should == '122.3'
    # res.should_not be_integer
    # res.should_not be_string
  end

  it 'should return integers' do
    cxt = H8::Context.new
    res = cxt.eval("0.2 + 122.1;")
    res.to_i.should == 122
    res.should_not be_integer
    res = cxt.eval("11+22;")
    res.to_i.should == 33
    res.should be_kind_of(Fixnum)
  end

  it 'should return floats' do
    cxt = H8::Context.new
    res = cxt.eval("0.2 + 122.1;")
    res.to_s.should == '122.3'
    res.should be_kind_of(Float)
  end

  it 'should return strings' do
    res = H8::Context.eval("'hel' + 'lo';")
    res.to_s.should == 'hello'
    res.should be_kind_of(String)
  end

  it 'should return undefined and null' do
    H8::Context.eval('undefined').should == H8::Undefined
    H8::Context.eval('null').should == nil
  end

  it 'should retreive JS fieds as indexes' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    res['foo'].to_s.should == 'bar'
    res['bar'].to_i.should == 122
  end

  it 'should retreive JS fields as properties' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    res.bar.to_i.should == 122
    res.foo.to_s.should == 'bar'
    res.foo.to_s.should == 'bar'
    res.bar.to_i.should == 122
    # cached method check
    res.foo.to_s.should == 'bar'
    res.bar.to_i.should == 122

    res.bad.should == H8::Undefined
    # res.bad.bad ?
  end

  it 'should access arrays' do
    res = H8::Context.eval("[-10, 'foo', 'bar'];")
    res.should_not be_undefined
    res.array?.should be_true
    res.length.should == 3
    3.times {
      res[0].to_i.should == -10
      res[1].to_s.should == 'foo'
      res[2].to_s.should == 'bar'
    }
    res[3].should == H8::Undefined
  end

  it 'should eval and keep context alive' do
    cxt = H8::Context.new
    wr  = WeakRef.new cxt
    obj = cxt.eval("({ 'foo': 'bar', 'bar': 122 });")
    cxt = nil
    GC.start # cxt is now kept only by H8::Value obj
    wr.weakref_alive?.should be_true
    obj.foo.should == 'bar'
  end

  it 'should keep alive references to js objects' do
    cxt = H8::Context.new
    jobj = cxt.eval 'var obj={foo: "bar"}; obj;'
    jobj.foo.should == 'bar'
    cxt.eval 'var obj = {foo: "buzz"};'
    GC.start
    cxt.javascript_gc()
    jobj.foo.should == 'bar'
    jobj.foo.should == 'bar'
    wobj = WeakRef.new jobj
    jobj = nil
    GC.start
    expect(wobj.weakref_alive?).not_to be_truthy
    cxt.javascript_gc()
    cxt = nil
    GC.start
  end

  it 'should keep alive references to ruby objects' do
    robj = 4096.times.map { |n| "-- #{n} --"}
    wobj = WeakRef.new robj
    cxt = H8::Context.new
    cxt[:obj] = robj
    GC.start
    cxt.javascript_gc
    expect(wobj.weakref_alive?).to be_truthy
    robj = nil
    GC.start
    cxt.javascript_gc
    expect(wobj.weakref_alive?).to be_truthy
    cxt.eval 'obj = null;'
    cxt[:obj] = 'nope'
    cxt.javascript_gc
    GC.start
    # pending # Why weakref is not freeed here?
    # expect(wobj.weakref_alive?).to be_falsey
  end

  it 'should convert simple types to ruby' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122, pi: 3.1415 });")
    r   = res.foo.to_ruby
    r.should be_kind_of(String)
    r.should == 'bar'

    r = res.bar.to_ruby
    r.should be_kind_of(Fixnum)
    r.should == 122

    r = res.pi.to_ruby
    r.should be_kind_of(Float)
    (r == 3.1415).should be_true
  end

  it 'should convert arrays to ruby' do
    res = H8::Context.eval("[-10, 'foo', 'bar'];")
    res.to_ruby.should == [-10, 'foo', 'bar']
    res.to_ary.should == [-10, 'foo', 'bar']
  end

  it 'should provide hash methods' do
    obj = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    obj.keys.should == Set.new(['foo', 'bar'])

    hash = {}
    obj.each { |k, v| hash[k] = v.to_ruby }
    hash.should == { "foo" => "bar", "bar" => 122 }
    obj.to_h.should == { "foo" => "bar", "bar" => 122 }
    obj.to_ruby.should == { "foo" => "bar", "bar" => 122 }

    Set.new(obj.each_key).should == Set.new(['foo', 'bar'])
    Set.new(obj.values.map(&:to_ruby)).should == Set.new(['bar', 122])
    Set.new(obj.each_value.map(&:to_ruby)).should == Set.new(['bar', 122])
  end

  it 'should convert compare to ruby objects' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    (res.foo != 'bar').should be_false
    (res.foo == 'bar').should be_true
    (res.foo != 'ba1').should be_true
    (res.foo == 'ba1').should be_false

    (res.bar != 'bar').should be_true
    (res.bar == 'bar').should be_false
    (res.bar != 122).should be_false
    (res.bar == 122).should be_true
    (res.bar <= 122).should be_true
    (res.bar <= 123).should be_true
    (res.bar >= 122).should be_true
    (res.bar >= 121).should be_true

    (res.bar > 120).should be_true
    (res.bar < 130).should be_true
    (res.bar > 129).should be_false
    (res.bar < 19).should be_false
  end

  it 'should call functions with no args' do
    res = H8::Context.eval "(function() { return 'sono callable'; });"
    res.call('a', '1', '2').should == 'sono callable'
  end

  it 'should call functions with args' do
    res = H8::Context.eval "(function(a, b) { return a + b; });"
    res.call('10', '1').should == '101'
    res.call(10, 1).should == 11
  end

  it 'should raise error on syntax' do
    expect(-> {
      H8::Context.eval 'this is not a valid js'
    }).to raise_error(H8::Error)
  end

  it 'should call member functions only' do
    res = H8::Context.eval <<-End
      function cls(base) {
        this.base = base;
        this.someVal = 'hello!';
        this.noArgs = function() { return 'world!'};
        this.doAdd = function(a, b) {
          return a + b + base;
        }
      }
      new cls(100);
    End
    res.someVal.should == 'hello!'
    res.noArgs.should == 'world!'
    res.doAdd(10, 1).should == 111
  end

  it 'should pass exceptions from member function calls' do
    res = H8::Context.eval <<-End
      function cls(base) {
        this.base = base;
        this.doAdd = function(a, b) {
          throw Error("Test error")
          return a + b + base;
        }
      }
      new cls(100);
    End
    expect(-> {
      res.doAdd(10, 1).should == 111
    }).to raise_error(H8::JsError) { |e|
            e.message.should == "Uncaught Error: Test error"
          }
  end

  it 'should call js functions' do
    res = H8::Context.eval <<-End
      var fn = function cls(a, b) {
        return a + ":" + b;
      }
      fn;
    End
    res.call('foo', 'bar').should == 'foo:bar'

    def xx(val, &block)
      "::" + val + "-" + block.call('hello', 'world')
    end

    xx("123", &res.to_proc).should == "::123-hello:world"
  end

  it 'should gate uncaught exceptions from js callbacks' do
    res = H8::Context.eval <<-End
      var fn = function cls(a, b) {
        throw Error("the test error");
      }
      fn;
    End
    expect(-> {
      res.call('foo', 'bar').should == 'foo:bar'
    }).to raise_error(H8::JsError)
  end

  it 'should pass thru uncaught ruby exceptions from js->ruby callbacks' do
    class MyException < StandardError;
    end;
    cxt            = H8::Context.new
    cxt[:bad_call] = -> { raise MyException }
    res            = cxt.eval <<-End
      var fn = function cls(a, b) {
        bad_call();
      }
      fn;
    End
    expect(-> {
      res.call('foo', 'bar').should == 'foo:bar'
    }).to raise_error(MyException)
  end

  it 'should dynamically add and remove properties to js objects' do
    cxt = H8::Context.new
    jobj = cxt.eval('jobj = {one: 1};')
    jobj.one.should == 1
    jobj['one'].should == 1
    jobj[:one].should == 1
    jobj.one = 101
    cxt.eval('jobj.one').should == 101
    jobj[:one].should == 101
    jobj.two = 2
    jobj[:two].should == 2
    cxt.eval('jobj.two').should == 2
    jobj[:three] = 3
    jobj.three.should == 3
    cxt.eval('jobj.three').should == 3
    jobj[101] = 202
    jobj[101].should == 202
    cxt.eval('jobj[101]').should == 202
  end

end
