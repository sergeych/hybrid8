require 'h8'
require 'pp'
require './tools'

def process_text text
  words = {}
  text.split(/\s+/).each { |w|
    w.downcase!
    next if w == 'which' || w == 'from' || w.length < 4
    w           = w[2..-1]
    rec         = words[w] ||= { word: w, count: 0 }
    rec[:count] += 1
  }
  words.values.sort { |a, b| b[:count] <=> a[:count] }[0..10]
end

base = File.dirname(File.expand_path(__FILE__))

text = open(base+'/big.txt').read
text = text * 2

cxt = js_context

coffee_process = cxt.eval coffee(:process_text)

coffee_res = ruby_res = nil

t1 = Thread.start {
  timing "ruby" do
    ruby_res = process_text text
  end
}

t2 = Thread.start {
  timing "coffee" do
    coffee_res = coffee_process.call text
  end
}

timing 'total' do
  t1.join
  t2.join
end

# pp coffee_res.to_ruby[0..4]
# pp ruby_res[0..4]
5.times { |n|
  coffee_res[n].word == ruby_res[n][:word] or raise "Words are different"
  coffee_res[n].count == ruby_res[n][:count] or raise "counts are different"
}

