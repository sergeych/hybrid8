require 'spec_helper'
require 'h8'

describe 'threading' do
  # it 'should run JS eval in threads in parallel' do
  #   class JsThread
  #     def initialize end_time
  #       @done = false
  #       @result = nil
  #       @t    = Thread.start {
  #         cxt = H8::Context.new
  #         cxt[:end] = end_time;
  #         @result = cxt.eval <<-End
  #           var count = 0;
  #           var endTime = end*1000;
  #           while( new Date().getTime() < endTime ) count++;
  #           (count);
  #         End
  #         @done = true
  #       }
  #     end
  #
  #     def join
  #       @t.join
  #       @result
  #     end
  #   end
  #
  #   end_time = Time.now.to_i + 1.5
  #   2.times { |n|
  #     t = JsThread.new end_time
  #     if t.join < 1
  #       p [n, t.join]
  #       fail "Threads do not run in parallel"
  #     end
  #   }
  # end

  before do
    @counter_script = <<-End
            var count = 0;
            //print('start');
            var endTime = end*1000 + 100;
            while( new Date().getTime() < endTime ) count++;
            //print('done');
            (count);
    End
    @context         = H8::Context.new
    @context[:print] = -> (*args) {
      puts "D: #{args.join(',')}"
    }
    sleep(0.01)
    @end_time      = Time.now.to_i + 1
    @context[:end] = @end_time
  end

  it 'without tout: should run JS/ruby threads in parallel' do
    cnt2 = 0
    t    = Thread.start {
      cnt2 += 1 while Time.now.to_i < @end_time
    }
    res  = @context.eval @counter_script, timeout: 5000
    # res =1
    cnt  = cnt2
    p [res, cnt]
    p res/cnt
    # p [res/cnt2]
    fail "JS thread does not run in parallel" if res < 1
    fail "JS thread does not run in parallel" if cnt < 1
    (res / cnt).should < 10
  end

  it 'should interrupt js' do
    err = nil
    t = Thread.start {
      begin
        @context.eval @counter_script
        p 'done!'
      rescue StandardError => e
        p '!!!', e
        err = e
      end
    }
    sleep(0.5)
    t.raise "test!"
    t.join
    err.should_not be_nil
    # t.kill
    # t.join
  end

  #
  # it 'should terminate JS from ruby thread' do
  #   # t = Thread.start
  # end
  #
  # it 'should run JS callables in threads in parallel'
  #
end
