require './tools'
require './km'


def js_context
  cxt         = H8::Context.new
  cxt[:print] = -> (*args) { puts args.join(' ') }
  cxt[:console] = Console
  cxt
end

def coffee script_file_name
  @base ||= File.dirname(File.expand_path(__FILE__))
  H8::Coffee.compile open("#{@base}/#{script_file_name}.coffee").read
end

cs = js_context.eval coffee(:knightsmove)

N = 7

res1 = res2 = 0
timing('total') {
  tt = []
  tt << Thread.start { timing('ruby', 1, 5) { res1 = Solver.new(N).to_s } }
  tt << Thread.start { timing('coffee', 5) { res2 = cs.call(N) } }
  tt.each &:join
}

if res1 != res2
  puts "WRONG RESULTS test data can not be trusted"
  puts "Ruby:\n#{res1}"
  puts "Coffee:\n#{res2}"
end

# puts res1
