require 'spec_helper'
require 'h8'

describe 'context' do

  it 'should create' do
    cxt = H8::Context.new
    cxt[:one] = 1
    cxt.eval("");
    # cxt.eval("'Res: ' + (2+5);")
  end

  it 'should gate simple values to JS context' do
    cxt = H8::Context.new foo: 'hello', bar: 'world'
    cxt[:sign] = '!'
    res = cxt.eval "foo+' '+bar+sign;"
    res.should == 'hello world!'
    cxt.set_all one: 101, real: 1.21
    cxt.eval("one + one;").should == 202
    cxt.eval("real + one;").should == (101 + 1.21)
  end

  it 'should gate H8::Values back to JS context' do
    cxt = H8::Context.new
    obj = cxt.eval "('che bel');"
    cxt[:first] = obj
    res = cxt.eval "first + ' giorno';"
    res.should == 'che bel giorno'
  end

  it 'should not gate H8::Values between contexts' do
    cxt = H8::Context.new
    obj = cxt.eval "({res: 'che bel'});"
    # This should be ok
    cxt[:first] = obj
    res = cxt.eval "first.res + ' giorno';"
    res.should == 'che bel giorno'
    # And that should fail
    cxt1 = H8::Context.new
    expect( -> {
      cxt1[:first] = obj
      res = cxt1.eval "first.res + ' giorno';"
    }).to raise_error(H8::Error)
  end

  it 'should provide reasonable undefined logic' do
    raise "bad !undefined" if !!H8::Undefined
    H8::Undefined.should_not == true
    H8::Undefined.should == false
    H8::Undefined.should_not == 11
    (H8::Undefined==nil).should == false
    H8::Undefined.should be_undefined
    (!H8::Undefined).should == true
  end

  it 'should limit script execution time' do
    cxt = H8::Context.new
    # cxt[:print] = -> (*args) { puts args.join(' ')}
    script = <<-End
      var start = new Date();
      var last = null;
      var counter = 0;
      while((last=new Date().getTime()) - start < 1000 ) {
        counter++;
      }
      counter;
    End
    # end
    t = Time.now
    expect( -> {
      c2 = cxt.eval script, max_time: 0.2
    }).to raise_error(H8::TimeoutError)
    (Time.now - t).should < 0.25
    cxt.eval('(last-start)/1000').should < 250
  end

  it 'should work in many threads' do
    sum = 0
    valid = 0
    n   = 10
    contexts = []
    tt  = n.times.map { |n|
      valid += (n+1)*100 + 10
      Thread.start {
        cxt         = H8::Context.new
        contexts << cxt
        cxt[:array] = 100024.times.map { |x| x*(n+1) }
        cxt[:n] = n+1
        sum         += cxt.eval('result = array[100] + 10')
      }
    }
    tt.each &:join
    sum.should == valid
    GC.start
    # Cross-thread access
    contexts.each { |cxt|
      s, n = cxt.eval('data = [result,n]')
      s.should == 100*n + 10
    }
  end


end
