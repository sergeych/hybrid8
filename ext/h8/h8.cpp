#include "h8.h"

Local<Value> h8::H8::gateObject(VALUE ruby_value) const {
	if ( Qtrue == rb_funcall(ruby_value, id_is_a, 1, value_class)) {
		JsGate *gate;
		Data_Get_Struct(ruby_value, JsGate, gate);
		if( gate->h8 != this ) {
			rb_raise(h8_exception, "H8::Value is bound to other H8::Context");
			return Undefined(isolate);
		}
		else
			return gate->value();
	}
	rb_raise(h8_exception, "Object gate is not implemented");
	return Undefined(isolate);
}
