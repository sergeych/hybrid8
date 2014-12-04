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
//	printf("Creating gate\n");
//	rb_raise(h8_exception, "Object gate is not implemented");
	return gate->handle(isolate);
}

void h8::H8::add_gate(RubyGate* gate) {
	// TODO: lock here!
	gate->prev = 0;
	gate->next = gates_head;
	gates_head = gate;
}

void h8::H8::remove_gate(RubyGate *gate) {
	// TODO: Lock here!
	if (gate->next) {
		gate->next->prev = gate->prev;
	}
	if (gate->prev) {
		gate->prev->next = gate->next;
	} else {
		// First item in the list
		gates_head = gate->next;
	}
}

void h8::H8::ruby_mark_gc() const {
	for (RubyGate* rg = gates_head; rg; rg = rg->next)
		rb_gc_mark(rg->ruby_object);
}

h8::H8::~H8() {
//	t("destructing");
	persistent_context.Reset();
	// TODO: free isolate!
//	isolate->Dispose();
}
