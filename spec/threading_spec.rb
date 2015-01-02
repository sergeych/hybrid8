require 'spec_helper'
require 'h8'

describe 'threading' do
  before do
    @counter_script = <<-End
            var count = 0;
            var endTime = end*1000 + 150;
            while( new Date().getTime() < endTime ) count++;
            (count);
    End
    @context         = H8::Context.new
    @context[:print] = -> (*args) {
      puts "D: #{args.join(',')}"
    }
    Thread.pass
    @end_time      = Time.now.to_i + 1
    @context[:end] = @end_time
  end

  it 'without tout: should run JS/ruby threads in parallel' do
    cnt2 = 0
    Thread.start {
      cnt2 += 1 while Time.now.to_i < @end_time
    }
    res  = @context.eval @counter_script, timeout: 5000
    cnt  = cnt2
    fail "JS thread does not run in parallel" if res < 1
    fail "JS thread does not run in parallel" if cnt < 1
    (res / cnt).should < 16
  end


  it 'should run JS callables in threads in parallel' do
    fn = @context.eval "res = function (end) { #{@counter_script} return count; }"
    cnt2 = 0
    Thread.start {
      cnt2 += 1 while Time.now.to_i < @end_time
    }
    res  = fn.call(@end_time)
    cnt  = cnt2
    fail "JS thread does not run in parallel" if res < 1
    fail "JS thread does not run in parallel" if cnt < 1
    (res / cnt).should < 16
  end
end
