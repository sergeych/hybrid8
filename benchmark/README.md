The most interesting benchmark is the classic knightsmove task. For 5 repitions 7x7 board on my i7
it gives:

    hybrid8/benchmark$ ruby knightsmove.rb
    coffee	: 3.970693
    ruby	: 13.152436 scaled: 65.76218
    total	: 13.152677

In other words, coffee and ruby rub in parallel (I have many cores) and coffee is roughly
*17 times faster* than ruby.

Moreover, if you run optimized C++ version, you'll have:

    hybrid8/benchmark$ g++ -O3 --std=c++11 km.cpp && ./a.out
    C++: 7.00417

which is, in turn, *1.76 times slower than coffeescript!*

The results are very inspiring, as for me.

## Some ruby platform comarisons

    ruby 2.1.5	: 13.767739 scaled: 68.838695
    ruby 2.2.0	: 12.859456 scaled: 64.29728
    rbx 2.1.0	: 9.35995 scaled: 46.799749999999996

Rbx, as expected, is way ahead of MRI but is still too bad to be compared to coffeescript/v8(h8)
