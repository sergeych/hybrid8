#include "h8.h"
#include "js_catcher.h"
#include <ruby/thread.h>

using namespace h8;

struct ApplyParams {
	Local<Object> object;
	Local<Value> &result;
	Local<Value>& self;
	Local<Value> *js_args;
	int count;
	H8* h8;
};

static inline void* call_without_gvl(void* param) {
	ApplyParams *ap = (ApplyParams*)param;
	ap->h8->setGvlReleased(true);
	ap->result = ap->object->CallAsFunction(ap->self, ap->count, ap->js_args);
	return NULL;
}

#define MAX_ARGS (128)

VALUE JsGate::apply(Local<Value> self, VALUE args) const {
	H8::Scope scope(h8);
	int count = RARRAY_LEN(args);
	if( count >= MAX_ARGS )
		throw JsError(h8, "Too many arguments for the callable");
//	Local<Value> *js_args = new Local<Value> [count];
	Local<Value> js_args[MAX_ARGS];
	for (int i = 0; i < count; i++) {
		js_args[i] = h8->to_js(rb_ary_entry(args, i));
	}
	h8::JsCatcher catcher(h8);
	Local<Value> result;

	ApplyParams ap = { object(), result, self, js_args, count, h8 };
	rb_thread_call_without_gvl(call_without_gvl, &ap, NULL, NULL );
	h8->setGvlReleased(false);

	catcher.throwIfCaught();
//	delete [] js_args;
	return h8->to_ruby(result);
}
