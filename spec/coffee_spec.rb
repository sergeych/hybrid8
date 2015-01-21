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
    expect(-> {
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
      # puts globalsIncluded
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
    cxt        = H8::Coffee.new.context
    cxt[:puts] = -> (*args) { puts args.join(' ') }
    cxt[:src]  = src
    # cxt[:src] = 'return "hello"'
    begin
      res = cxt.eval script, file_name: 'extest.coffee'
    rescue Exception => e
      puts e
    end
  end

  context 'realword' do
    class Room
    end

    it 'should process varargs' do
      c = H8::Context.new
      c[:puts] = ->(*args) { puts "> "+args.join('') }
      c.coffee <<-End
        @.fn1 = (args...) ->
          args.join(',')

        @.test = (args...) ->
          fn1 'first', args...
      End
      c.coffee('return test(1,2,3);').should == 'first,1,2,3'

      # Real world example
      c[:r3] = -> (*args) {
        @last_args = args
      }
      c[:r4] = -> (first, second=0) {
        [first+100, second]
      }
      script = <<-End
        @r1 = (args...) ->
          r3 'done', args[0..-2]...
        @r2 = (args...) ->
          r4 args...
      End
      c.coffee script
      c.eval('r1( "now", 1, 2, 4);').should == ['done', 'now', 1, 2]
      c.eval('r2( 100, 200);').should == [200, 200]
    end
  end
end
