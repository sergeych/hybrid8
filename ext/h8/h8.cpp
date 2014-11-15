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
	delete (Gate*) ptr;
}

static VALUE rvalue_alloc(VALUE klass) {
	return Data_Wrap_Struct(klass, 0, rvalue_free, new Gate);
}

inline Gate* rv(VALUE self) {
	Gate *gate;
	Data_Get_Struct(self, Gate, gate);
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

static VALUE rvalue_is_string(VALUE self) {
	return rv(self)->is_string();
}

inline H8* rc(VALUE self) {
	H8 *prcxt;
	Data_Get_Struct(self, H8, prcxt);
	return prcxt;
}

static VALUE context_set_instance(VALUE self, VALUE name, VALUE instance) {
	return Qnil;
}

void test1(Isolate* isolate) {
	EscapableHandleScope scope(isolate);
	cout << "111" << endl;
}

static VALUE context_eval(VALUE self, VALUE script) {

	H8* cxt = rc(self);
	H8::Scope s(cxt);

	Handle<Value> res = cxt->eval(StringValueCStr(script));
	if (cxt->isError())
		return Qnil;

    Gate *gate;
    VALUE ruby_gate = rb_class_new_instance(0, NULL, value_class);
    Data_Get_Struct(ruby_gate, Gate, gate);
    gate->set(cxt, res);
    return ruby_gate;
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

	h8_exception = rb_define_class_under(h8, "Error", rb_eStandardError);

}
