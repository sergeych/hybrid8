require 'spec_helper'
require 'h8'

describe 'context' do

  it 'should create' do
    cxt = H8::Context.new
    cxt.eval("'Res: ' + (2+5);")
  end

  it 'should gate simple values to JS context' do
    cxt = H8::Context.new foo: 'hello', bar: 'world'
    cxt[:sign] = '!'
    res = cxt.eval "foo+' '+bar+sign;"
    res.should == 'hello world!'
    cxt.set one: 101, real: 1.21
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
    obj = cxt.eval "('che bel');"
    cxt1 = H8::Context.new
    expect( -> {
      cxt1[:first] = obj
      res = cxt1.eval "first + ' giorno';"
    }).to raise_error(H8::Error)
  end

end
