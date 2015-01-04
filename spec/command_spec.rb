require 'spec_helper'
require 'h8/command'
require 'stringio'

describe 'cli' do

  before :each do
    @out     = StringIO.new '', 'w'
    @err     = StringIO.new '', 'w'
    @command = H8::Command.new out: @out, err: @err
  end

  def output
    @out.string
  end

  def errors
    @err.string
  end

  def run *args
    @out.string = ''
    @err.string = ''
    @command.run *(['-e'] + args)
    output
  end

  def make_path *path_components
    File.expand_path(File.join(File.dirname(__FILE__), *path_components))
  end

  it 'should print usage' do
    expect(-> { @command.run }).to raise_error(RuntimeError, "Must provide at least one file")
    expect(@command.usage =~ /Usage:/).to be_truthy
    # puts @command.usage
  end

  it 'should print' do
    run 'print "hello"; console.log "world"; console.error "life sucks!"'
    output.should == "hello\nworld\n"
    errors.should == "life sucks!\n"
  end

  it 'should read files' do
    path   = make_path '../lib/h8/coffee-script.js'
    length = "#{open(path).read.length}\n"
    run("print open('#{path}').read().length").should == length
    run("open('#{path}', 'r', (f) -> puts (" "+f.read().length) )").should == length
  end

  it 'should run tests' do
    begin
      @command.run make_path('coffee/cli_tests.coffee')
    rescue
      puts "Error: #{$!}\n#{$!.backtrace.join("\n")}"
    end
    log = @out.string.lines
    failed = log[-1] !~ /All tests passed/
    err    = @err.string.strip
    if err != ''
      puts '----------- Tests Error output ---------------'
      puts @err.string
    end
    if log.length > 1
      puts '---------------- Tests output --------------------'
      puts log[0..-2].join('')
      puts '--------------- End tests output -----------------'
    end
    failed and fail 'cli_tests.coffee failed'
  end
end

