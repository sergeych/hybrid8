require 'spec_helper'
require 'h8'

describe 'context' do
  it 'should create' do
    cxt = H8::Context.new
    cxt.eval("'Res: ' + (2+5);")
  end

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
    res.should be_integer
    res.should be_float
    res.should_not be_string
  end

  it 'should return floats' do
    cxt = H8::Context.new
    res = cxt.eval("0.2 + 122.1;")
    res.to_s.should == '122.3'
    res.should be_float
    res.should_not be_integer
    res.should_not be_string
  end

  it 'should return strings' do
    res = H8::Context.eval("'hel' + 'lo';")
    res.to_s.should == 'hello'
    res.should be_string
    res.should_not be_integer
    res.should_not be_float
  end

  it 'should retreive JS fieds as indexes' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    res['foo'].to_s.should == 'bar'
    res['bar'].to_i.should == 122
  end

  it 'should retreive JS fieds as properties' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    p res
    res.respond_to?(:foo).should be_true
    res.foo.to_s.should == 'bar'
    res.bar.to_i.should == 122
  end

end
