# Hybrid8, aka H8

_Warning_ this gem is a public beta at the moment - beta testers are welcome!It means, it is not
yet production stable - we haven't yet tried.

This gem was intended to replace therubyracer for many reasons:

* therubyracer has critical bugs that are not fixed for a long time, under load it produces
numerous frequent crashes.

* therubyracer still uses antique version of V8, H8 uses the latest 3.31 branch, which, for example,
has the generators support.

* H8 is designed to provide very tight and effective integration of two allocation systems and
object models, passing the same objects between different systems wrapping and unwrapping them
rather than copying and changing

* We hope that by the cost non significant changes we will provide faster execution. And might v8
modern branch will help us with it ;)

Special features:

- care about wrapped Ruby objects lifespan (are kept until either ruby or javascript context
reference wrapped object). In no way GC will not reclaim ruby object that is in use by the
javascript context

- care about wrapped Javascript objects lifetime the same. Referenced JS items will not be recycled
while there are ruby objects referencing it. It also means that once created H8::Context will not
be reclaimed as long as there is at least one active wrapped object returned from the script.

- you can pass ruby objects from ruby code called from javascript back to the ruby code intact.
Ruby objects are automatically wrapped in js code and unwrapped in ruby code (you might need to
call #to_ruby)

- Uncaught ruby exceptions are thrown as javascript exceptions in javascript code. The same,
uncaught javascript exceptions raise ruby error in ruby code.

- Integrated CoffeeScript support

- H8 is thread safe (using Lockers) and releases gvl when executing js code (and reqcquires it as
need), thus other ruby threads can work in parallel with javascript executing threads. Still,
h8 does not releases Locker when calling ruby code from javascript - for performance considerations.


## Main difference from therubyracer/features not ready

- labmda/proc passed as var to the context **does not receives first (this) argument
automatically!**

E.g. rubyracer code

    cxt[:fn] = -> (this, a, b) { a + b }

Becomes

    cxt[:fn] = -> (a, b) { a + b }

it looks prettier, doesn't it? And, if you really need `this` in the callable, just mention it in
the call:

    cxt[:fn] = -> (this, a, b) { a + b + this.offset }
    cxt.eval 'fn(this, 10, 20)'

This, again, is done for execution speed. Always wrapping `this` to pass it to ruby is a costly
procedure which is always performed in rubyracer - no matter is it really needed. In H8 you can
spend your resources only when it worth extra processing. From my experience, it is a rare situation
when such a lambda needs javascript's this - but, no problem, pass it this, or whatever else
you need ;)

- there is no 'Context object initialization' - it does not work well in rubyracer so it is not
likely used widely. We can add it later, though - if you need it, add an issue.



## Installation

### Prerequisites

You should have installed libv8, use latest version with v8::Isolate and v8::Locker. This version
may not find you installation, contact me if you have problems, I'll tune it up.

#### Macos (10.9 maybe+)

The working process:

install v8 from sources 3.31.77 (or try newer), then execute:

    gclient update
    export CXXFLAGS='-std=c++11 -stdlib=libc++ -mmacosx-version-min=10.9'
    export LDFLAGS=-lc++
    make native
    export V8_3_31_ROOT=`pwd` # or somehow else set it

Note that exporting symbols is a hack that may not be in need anymore. After that the gem should
install normally.

#### Debian and like

Install first a valid v8 version. We provide a ready package!

    sudo apt-get install libv8-3.31-dev

Usually it is all you need. Rarely, You might also need to install GMP.

### Setting up

Add this line to your application's Gemfile:

    gem 'hybrid8'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hybrid8

## Usage

Is generally like therubyracer gem. Create context, set variables, run scripts.

    require 'h8'

    res = H8::Context.eval "({foo: 'hello', bar: 'world'});"
    puts "#{res.foo} #{res.bar}"

another way to access attributes:

    puts res['foo']

The same works with arrays:

    res = H8::Context.eval "['foo', bar'];"
    puts res[1]

To set context variables:

    cxt = H8::Context.new some: 'value'
    cxt[:pi] = 3.1415

You can return function and call it from ruby:

    fun = cxt.eval "(function pi_n(n) { return pi * n; })"
    p fun(2)

The same you can return objects and call its member functions - if a member is a function,
it will be called with given arguments:

    res = H8::Context.eval <<-End
      function cls(base) {
        this.base = base;
        this.someVal = 'hello!';
        this.noArgs = function() { return 'world!'};
        this.doAdd = function(a, b) {
          return a + b + base;
        }
      }
      new cls(100);
    End
    res.someVal.should == 'hello!'
    res.noArgs.should == 'world!'
    res.doAdd(10, 1).should == 111

## Contributing

Note that at this early point of development you better first talk to me to not to reinvent the
wheel.

1. Fork it ( https://github.com/[my-github-username]/hybrid8/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


