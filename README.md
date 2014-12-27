# Hybrid8, aka H8

_Warning_ this gem is a beta at the moment. I will be pleased if you try it and help me debug it,
but it is not yet production stable.

This gem was intended to replace therubyracer for many reasons:

* therubyracer has critical bugs that are not fixed for a long time, under load it produces
numerous frequent crashes.

* therubyracer still uses antique version of V8, H8 uses the latest 3.31 branch

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

## Main difference from therubyracer/features not ready

- This version is not (yet?) thread safe*. For the sake of effectiveness, do not access same
H8::Context and its returned values from concurrent threads. Use Mutexes if need.

The pity thing is, if we will Lock() the context on each call to it, the performance degradation
will be notable and no matter whether you need threading with it. So, if you really need it, you
wrap it with Mutex or whatever you want, without slowing down all the rest of us.

- Script is executed in the calling ruby thread without unblocking it (other ruby threads can not
 perform on this core while javascript code runs).

The same performance reason. If we release gvl on script start and reacquire it every time the ruby
object, callback, class, whatever is referenced from JS, the execution will considerably degrade. As
this gem is intended to let javascript/coffescript tightly integrate with ruby objects we have
decided to not to slow down everything. If it is a problem, lets discuss it.

- correct and accurate object tracking in both JS and Ruby VMs, GC aware.

- Not Yet: source information in uncaught exception in js


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

It should install prerequisites, if not, manually install

    sudo apt-get install libicu-dev

You might also need to install GMP.

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


