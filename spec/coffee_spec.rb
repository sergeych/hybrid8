require 'spec_helper'
require 'h8'

describe 'coffeescript' do

  Cs_0 = <<-END
    test = (a, b) ->
      "result: \#{a} \#{b}"
    return test('coffee', 'rules')
  END

  Res_0 = 'result: coffee rules'

  it 'should compile and execute' do
    c = H8::Coffee.new
    H8::Context.eval(c.compile(Cs_0)).should == Res_0
    c.eval(Cs_0).should == Res_0
    c.eval(Cs_0).should == Res_0
  end

  it 'should provide compiler singleton' do
    H8::Coffee.eval(Cs_0).should == Res_0
    H8::Coffee.eval(Cs_0).should == Res_0
    H8::Context.eval(H8::Coffee.compile Cs_0).should == Res_0
    H8::Context.eval(H8::Coffee.compile Cs_0).should == Res_0
  end

end
