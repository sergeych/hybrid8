#include "h8.h"
#include "JsCatcher.h"

using namespace h8;

VALUE JsGate::apply(Local<Value> self, VALUE args) const {
	H8::Scope scope(h8);
	long count = RARRAY_LEN(args);
	Local<Value> *js_args = new Local<Value> [count];
	for (int i = 0; i < count; i++) {
		js_args[i] = h8->to_js(rb_ary_entry(args, i));
	}
	h8::JsCatcher catcher(h8);
	Local<Value> result = object()->CallAsFunction(self, count, js_args);
	catcher.throwIfCaught();
	delete [] js_args;
	return h8->to_ruby(result);
}
