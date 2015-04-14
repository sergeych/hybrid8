# Hybrid8, aka H8

Current development state: works in production environment.

This gem was intended to replace therubyracer for many reasons:

* therubyracer has/had critical bugs that are not being fixed for a long time. As the result it produces numerous and frequent random crashes under load.

* therubyracer still uses antique version of V8. H8 uses the latest 3.31 branch, which has many
improvements, harmony support and so on.

* H8 is designed to provide tight integration between two allocation systems and object models,
passing the same objects within different systems, wrapping and unwrapping them rather than copying
and changing.

* We hope to provide faster execution with a tradeoff in non-significant changes. And let the modern branch of V8
 help us with it ;)

Special features:

- H8 takes care of wrapped Ruby objects lifespan. Objects live until either ruby or javascript context
references them. GC will not reclaim memory occupied by ruby object while it is used by javascript context.

- H8 takes care of wrapped Javascript objects lifetime in the same way. Referenced JS items will not be recycled
while there are ruby objects referencing them. It also means that once created H8::Context will not
be reclaimed as long as there is at least one active wrapped object returned from a script.

- You can pass ruby objects from ruby code called from javascript back to the ruby code intact.
Ruby objects are automatically wrapped in js code and unwrapped in ruby code (you might need to
call #to_ruby).

- Uncaught ruby exceptions are thrown as javascript exceptions in javascript code. Likewise,
uncaught javascript exceptions raise ruby errors in ruby code.

- Integrated CoffeeScript support.

- H8 is thread safe. It releases gvl lock while executing ruby code and unlocks V8 isolate when
calling ruby code thus maximally allows the possibility of parallel execution of ruby and javascript code
in separate threads.

Due to V8 and ruby MRI limitations, only one ruby thread can access any given H8::Context (e.g.
execute javascript code in it) and, as usual, all ruby threads are locked by a single mutex (gvl).
Still, having multiple H8::Context in different ruby threads lets you run many java/coffee scripts in
parallel with a single ruby thread - what you can not have with pure MRI ruby.

## Main differences from therubyracer and future features

- lambda/proc passed as var to the context **does not receive first (this) argument
automatically!**

E.g. rubyracer code

    cxt[:fn] = -> (this, a, b) { a + b }

Becomes

    cxt[:fn] = -> (a, b) { a + b }

Looks nicer, doesn't it? And if you really need `this` in the callable, just mention it in
the call:

    cxt[:fn] = -> (this, a, b) { a + b + this.offset }
    cxt.eval 'fn(this, 10, 20)'

This, again, is done to improve execution speed. Always wrapping `this` to pass it to ruby is a costly
procedure which is always performed in rubyracer - no matter if it is really needed or not. In H8 you can
spend your resources only when it is worth extra processing. From my experience, it is a rare situation
when such a lambda needs javascript's this - but you still have the possibility if you need it ;)

- there is no 'Context object initialization'. It does not work well in rubyracer, so it's not
likely that it's widely used. We can add it later, though - if you need it, add an issue.



## Installation

### Prerequisites

You should have libv8 installed, use the latest version with v8::Isolate and v8::Locker. It might not find your installation, contact me if you have problems - I'll tune it up.

#### Macos (10.9 maybe+)

The working process:

install V8 from sources 3.31.77 (or try newer), then execute:

    gclient update
    export CXXFLAGS='-std=c++11 -stdlib=libc++ -mmacosx-version-min=10.9'
    export LDFLAGS=-lc++
    make native
    export V8_3_31_ROOT=`pwd` # or somehow else set it

Note that exporting symbols is a hack that may not be needed anymore. After that the gem should
install normally.

#### Debian and like

First install a valid v8 version. We provide a ready-to-use package!

    sudo apt-get install libv8-3.31-dev

Usually it's all you need. In rare cases you might also need to install GMP.

### Setting up

Add this line to your application's Gemfile:

    gem 'hybrid8'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hybrid8

## Usage

Is's generally like therubyracer gem. Create context, set variables, run scripts.

    require 'h8'

    res = H8::Context.eval "({foo: 'hello', bar: 'world'});"
    puts "#{res.foo} #{res.bar}"

Another way to access attributes:

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

Likewise, you can return objects and call it's member functions. If a member is a function,
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

Note that at this early point of development it's better that you talk to me first to not to reinvent the
wheel.

1. Fork it ( https://github.com/[my-github-username]/hybrid8/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


