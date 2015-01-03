require 'h8'

def timing name
  s = Time.now
  yield
  puts "#{name}\t: #{Time.now - s}"
rescue
  puts "*** #{$!}"
  raise
end

def js_context
  cxt         = H8::Context.new
  cxt[:print] = -> (*args) { puts args.join(' ') }
  cxt
end

def coffee script_file_name
  @base ||= File.dirname(File.expand_path(__FILE__))
  H8::Coffee.compile open("#{@base}/#{script_file_name}.coffee").read
end
