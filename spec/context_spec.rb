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

  it 'should limit script execution time' do
    # cxt = H8::Context.new
    # cxt[:print] = -> (*args) { puts args.join(' ')}
    # counter = 0
    # t = Thread.start {
    #   start = Time.now
    #   counter+=1 while Time.now - start < 1
    # }
    # c2 = cxt.eval <<-End
    #   var start = new Date();
    #   var counter = 0;
    #   while(new Date().getTime() - start < 1000 ) {
    #     counter++;
    #   }
    #   counter;
    # End
    # t.join
    # p c2
    # p counter

  end

end
