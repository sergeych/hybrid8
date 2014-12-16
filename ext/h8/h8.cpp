#include "h8.h"
#include "ruby_gate.h"

Local<Value> h8::H8::gateObject(VALUE ruby_value) {
	if ( Qtrue == rb_funcall(ruby_value, id_is_a, 1, value_class)) {
		JsGate *gate;
		Data_Get_Struct(ruby_value, JsGate, gate);
		if (gate->h8 != this) {
			rb_raise(h8_exception, "H8::Value is bound to other H8::Context");
			return Undefined(isolate);
		} else
			return gate->value();
	}
	// Generic Ruby object
	RubyGate *gate = new RubyGate(this, ruby_value);
	return gate->handle(isolate);
}

void h8::H8::ruby_mark_gc() const {
	for(chain::link *x: resources)
		((AllocatedResource*)x)->rb_mark_gc();
}

h8::H8::~H8() {
	t("destructing H8!");

	while( !resources.is_empty() ) {
		t("resource found");
		// this should also remove it from the list:
		resources.peek_first<AllocatedResource>()->free();
	}

	persistent_context.Reset();
	// TODO: free isolate!
	isolate->Dispose();
}
