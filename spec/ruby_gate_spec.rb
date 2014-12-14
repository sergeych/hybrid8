require 'spec_helper'
require 'h8'

describe 'ruby gate' do

  it 'should gate callables' do
    cxt = H8::Context.new
    cxt[:fn] = -> (a, b) {
      a + b
    }

    res = cxt.eval "fn(11, 22);"
    res.to_i.should == 33
    cxt = nil
    res = nil
    GC.start
  end

  it 'should object properties'
  it 'should object methods'
  it 'should retain ruby objects'
  it 'should gate classes'
end
