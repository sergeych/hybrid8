#ifndef _h8_h
#define _h8_h

#include <v8.h>
#include <ruby.h>
#include <iostream>

using namespace v8;
using namespace std;

//#include <ruby/thread.h>



extern VALUE h8_exception;
extern VALUE h8_class;

typedef VALUE (*ruby_method)(...);

#include "rcontext.h"
#include "rvalue.h"


#endif
