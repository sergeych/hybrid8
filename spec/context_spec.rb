require 'spec_helper'
require 'h8'

describe 'context' do

  it 'should create' do
    cxt = H8::Context.new
    cxt.eval("'Res: ' + (2+5);")
  end


end
