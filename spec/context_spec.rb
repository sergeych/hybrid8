require 'spec_helper'
require 'h8'

describe 'context' do
  it 'should create' do
    cxt = H8::Context.new
    cxt.eval("122.1;")
  end

  it 'should return number as string' do
    cxt = H8::Context.new
    res = cxt.eval("0.2 + 122.1;")
    res.to_s.should == '122.3'
    res.should_not be_integer
    res.should_not be_string
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

end
