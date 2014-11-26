#include "h8.h"

Local<Value> h8::H8::gateObject(VALUE ruby_value) const {
	if ( Qtrue == rb_funcall(ruby_value, id_is_a, 1, value_class)) {
		JsGate *gate;
		Data_Get_Struct(ruby_value, JsGate, gate);
		String::Utf8Value res(gate->value());
		return gate->value();
	}
	printf("\n\n\nbut it IS object\n\n\n");
	rb_raise(h8_exception, "Object gate is not implemented");
	return Undefined(isolate);
}
