require 'spec_helper'
require 'h8'

describe 'context' do

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
    res.bar.to_i.should == 122
    res.foo.to_s.should == 'bar'
    res.foo.to_s.should == 'bar'
    res.bar.to_i.should == 122
    # cached method check
    res.foo.to_s.should == 'bar'
    res.bar.to_i.should == 122
  end

  it 'should access arrays' do
    res = H8::Context.eval("[-10, 'foo', 'bar'];")
    res.should_not be_undefined
    3.times {
      res[0].to_i.should == -10
      res[1].to_s.should == 'foo'
      res[2].to_s.should == 'bar'
    }
  end

  it 'should raise error on indexing undefineds'
  it 'should raise error on accessing fields of undefineds'

end
