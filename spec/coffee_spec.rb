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
    H8::Context.new.coffee(Cs_0).should == Res_0
  end

  it 'should report syntax errors' do
    script = <<-END
      # Started: ok
      square = (x) -> x*x
      # so far so good but then...
      baljkhl9399-^&
      # above is bad
    END
    # pending
    expect(->{
      H8::Coffee.compile script, file_name: 'test.coffee'
    }).to raise_error(H8::JsError) { |e| e.to_s.should =~ /test.coffee\:4/ }
  end

  it 'should report exceptions' do
    src = <<-END
      fnb = ->
        throw new Error 'lets check'
      fna = ->
        fnb()
      CoffeeScript.getSourceMap = (name) ->
        puts "DUMMUY \#{name}"
        undefined

      # fna()
      puts globalsIncluded
    END
    script = <<-END
      function require(name) {
        puts("REQ! "+name);
      }
      var res = CoffeeScript.compile(src, {sourceMap: true, filename: 'inner.coffee'});
      //var sourceMaps = { 'inner.coffee' : res.sourceMap }
      // puts("Compiled ok",JSON.stringify(CoffeeScript.sourceMaps));
      // CoffeeScript.sourceMaps['inner'] = res.sourceMap
      eval(res.js);
    END
    cxt = H8::Coffee.new.context
    cxt[:puts] = -> (*args) { puts args.join(' ') }
    cxt[:src] = src
    # cxt[:src] = 'return "hello"'
    begin
    res = cxt.eval script, file_name: 'extest.coffee'
    p res
    rescue Exception=>e
      puts e
    end
  end

end
