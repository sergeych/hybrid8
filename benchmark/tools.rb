# require 'h8'

def timing name, repetitions = 1, scale = 1
  s = Time.now
  repetitions.times { yield }
  t = Time.now - s
  if scale != 1
    puts "#{name}\t: #{t} scaled: #{t*scale}"
  else
    puts "#{name}\t: #{t}"
  end
rescue
  puts "*** #{$!}"
  raise
end

class Console
  def log *args
    puts args.join(' ')
  end
end

