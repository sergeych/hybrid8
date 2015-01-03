require 'h8'
require 'pp'

def timing name
  s = Time.now
  yield
  puts "#{name}\t: #{Time.now - s}"
end

def process_text text
  words = {}
  text.split(/\s+/).each { |w|
    w.downcase!
    next if w == 'which' || w == 'from' || w.length < 4
    w = w[2..-1]
    rec = words[w] ||= {word: w, count: 0}
    rec[:count] += 1
  }
  words.values.sort{ |a,b| b[:count] <=> a[:count] }[0..10]
end

base = File.dirname(File.expand_path(__FILE__))

text = open(base+'/big.txt').read
text = text * 6

cxt = H8::Context.new
cxt[:print] = -> (*args) { puts args.join(' ')}

script = H8::Coffee.compile open(base+'/process_text.coffee').read
# puts script
coffee_process = cxt.eval script

coffee_res = ruby_res = nil
timing "ruby" do
  ruby_res = process_text text
end

timing "coffee" do
  coffee_res = coffee_process.call text
end

# pp coffee_res.to_ruby[0..4]
# pp ruby_res[0..4]
5.times { |n|
  coffee_res[n].word == ruby_res[n][:word] or raise "Words are different"
  coffee_res[n].count == ruby_res[n][:count] or raise "counts are different"
}

