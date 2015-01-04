require 'spec_helper'
require 'h8'
require 'h8/pargser'

describe 'pargser' do

  it 'should parse keys' do
    parser = H8::Pargser.new "-a -b -v value! other data".split
    parser.key('-a', doc: 'flag to perform a action') {
      @a_called = true
    }
        .key('-c', '-b') {
      @b_called = true
    }
        .key('--some', default: 'test') { |v|
      @defvalue = v
    }
        .key('-v', needs_value: true) { |v|
      @v = v
    }
    expect(-> { parser.key('-a') }).to raise_error(H8::Pargser::Error)

    passed = []
    rest   = parser.parse { |a| passed << a }
    rest.should == passed
    rest.should == ['other', 'data']

    @a_called.should be_truthy
    @b_called.should be_true
    @v.should == 'value!'
    @defvalue.should == 'test'

    doc = "\t-a\n\t\tflag to perform a action\n\t-c,-b\n\t--some value (default: test)\n\t-v value"
    parser.keys_doc.should == doc
  end

  it 'should detect required keys' do
    parser = H8::Pargser.new ['hello']
    parser.key('-c', needs_value: true) {}
    expect(-> { parser.parse }).to raise_error(H8::Pargser::Error, 'Required key is missing: -c')
  end

  it 'should detect strange keys' do
    parser = H8::Pargser.new '-l hello'.split
    expect(->{ parser.parse }).to raise_error(H8::Pargser::Error, 'Unknown key -l')
  end

  it 'should pass data that looks like keys' do
    res = H8::Pargser.new('-- -a --b'.split).parse
    res.should == ['-a', '--b']
  end

  it 'should provide empty defaults' do
    parser = H8::Pargser.new('hello'.split)
    @t == 'wrong'
    parser.key('-t', default: nil) { |val|
      @t = val
    }
    parser.key('-q', default: false) { |val|
      @q = val
    }
    parser.parse.should == ['hello']
    @t.should == nil
    @q.should == false
  end

end
