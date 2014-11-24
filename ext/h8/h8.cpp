#include <h8.h>
#include <include/libplatform/libplatform.h>

using namespace h8;

extern "C" {
void Init_h8(void);
}

VALUE h8_exception;
VALUE context_class;
VALUE value_class;

static void rvalue_free(void* ptr) {
	delete (JsGate*) ptr;
}

VALUE rvalue_alloc(VALUE klass) {
	return Data_Wrap_Struct(klass, 0, rvalue_free, new JsGate);
}

inline JsGate* rv(VALUE self) {
	JsGate *gate;
	Data_Get_Struct(self, JsGate, gate);
	return gate;
}

static VALUE rvalue_to_s(VALUE self) {
	return rv(self)->to_s();
}

static VALUE rvalue_to_i(VALUE self) {
	return rv(self)->to_i();
}

static VALUE rvalue_is_int(VALUE self) {
	return rv(self)->is_int();
}

static VALUE rvalue_is_float(VALUE self) {
	return rv(self)->is_float();
}

static VALUE rvalue_get_attr(VALUE self,VALUE name) {
	return rv(self)->get_attribute(name);
}

static VALUE rvalue_is_string(VALUE self) {
	return rv(self)->is_string();
}

inline H8* rc(VALUE self) {
	H8 *prcxt;
	Data_Get_Struct(self, H8, prcxt);
	return prcxt;
}

static VALUE context_eval(VALUE self, VALUE script) {
	H8* cxt = rc(self);
	H8::Scope s(cxt);

	Handle<Value> res = cxt->eval(StringValueCStr(script));
	if (cxt->isError())
		return Qnil;

    return JsGate::to_ruby(cxt, res);
}

static void context_free(void* ptr) {
	delete (H8*) ptr;
}

static VALUE context_alloc(VALUE klass) {
	return Data_Wrap_Struct(klass, 0, context_free, new H8);
}

void init_v8() {
	v8::V8::InitializeICU();
	v8::Platform* platform = v8::platform::CreateDefaultPlatform();
	v8::V8::InitializePlatform(platform);
	v8::V8::Initialize();
}

void Init_h8(void) {
	init_v8();

	VALUE h8 = rb_define_module("H8");

	context_class = rb_define_class_under(h8, "Context", rb_cObject);
	rb_define_alloc_func(context_class, context_alloc);
	rb_define_method(context_class, "eval", (ruby_method) context_eval, 1);

	value_class = rb_define_class_under(h8, "Value", rb_cObject);
	rb_define_alloc_func(value_class, rvalue_alloc);
	rb_define_method(value_class, "to_s", (ruby_method) rvalue_to_s, 0);
	rb_define_method(value_class, "to_i", (ruby_method) rvalue_to_i, 0);
	rb_define_method(value_class, "integer?", (ruby_method) rvalue_is_int, 0);
	rb_define_method(value_class, "float?", (ruby_method) rvalue_is_float, 0);
	rb_define_method(value_class, "string?", (ruby_method) rvalue_is_string,
			0);
	rb_define_method(value_class, "get_attr", (ruby_method) rvalue_get_attr,
			1);

	h8_exception = rb_define_class_under(h8, "Error", rb_eStandardError);

}
