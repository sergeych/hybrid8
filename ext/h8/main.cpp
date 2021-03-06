#include <functional>
#include <h8.h>
#include <include/libplatform/libplatform.h>

using namespace h8;

extern "C" {
void Init_h8(void);
}

VALUE h8_exception, js_exception, js_timeout_exception, js_nested_exception;
VALUE context_class;
VALUE ruby_gate_class;
VALUE value_class;
VALUE Rundefined;

ID id_is_a, id_safe_call, id_safe_proc_call, id_delete_handler;

VALUE protect_ruby(const std::function<VALUE()> &block) {
	try {
		return block();
	} catch (JsError& e) {
		try {
			e.raise();
		}
		catch(...) {
			rb_raise(js_exception, "error while converting JS exception (pls report a bug)");
		}
	} catch (...) {
		rb_raise(rb_eStandardError, "unknown error in JS");
	}
	return Qnil;
}

static void rvalue_free(void* ptr) {
	delete ((JsGate*) ptr);
}

static void rvalue_mark(void* ptr) {
	JsGate *gate = (JsGate*) ptr;
	gate->rb_mark_gc();
}

VALUE rvalue_alloc(VALUE klass) {
	return Data_Wrap_Struct(klass, rvalue_mark, rvalue_free, new JsGate);
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

static VALUE rvalue_to_f(VALUE self) {
	return rv(self)->to_f();
}

static VALUE rvalue_is_undefined(VALUE self) {
	return rv(self)->is_undefined();
}

static VALUE rvalue_get_attr(VALUE self, VALUE name) {
	return rv(self)->get_attribute(name);
}

static VALUE rvalue_get_index(VALUE self, VALUE index) {
	return rv(self)->get_index(index);
}

static VALUE rvalue_set_attr(VALUE self, VALUE name, VALUE value) {
	return protect_ruby([&] {
		rv(self)->set_attribute(name, value);
		return Qnil;
	});
}

static VALUE rvalue_is_string(VALUE self) {
	return rv(self)->is_string();
}

static VALUE rvalue_is_array(VALUE self) {
	return rv(self)->is_array();
}

static VALUE rvalue_is_object(VALUE self) {
	return rv(self)->is_object();
}

static VALUE rvalue_is_function(VALUE self) {
	return rv(self)->is_function();
}

static VALUE rvalue_call(VALUE self, VALUE args) {
	return protect_ruby([&] {
		return rv(self)->call(args);
	});
}

static VALUE rvalue_apply(VALUE self, VALUE to, VALUE args) {
	return protect_ruby([&] {
		return rv(self)->apply(to, args);
	});
}

static VALUE rvalue_get_ruby_context(VALUE self) {
	return rv(self)->ruby_context();
}

//------------ context ----------------------------------------------------------------

inline H8* rc(VALUE self) {
	H8 *prcxt;
	Data_Get_Struct(self, H8, prcxt);
	return prcxt;
}

static VALUE context_eval(VALUE self, VALUE script, VALUE timeout,
		VALUE script_name_ruby) {
	return protect_ruby([&] {
		H8* cxt = rc(self); //		v8::Locker l(cxt->getIsolate());
			H8::Scope s(cxt);
			const char* script_name = script_name_ruby != Qnil ? StringValueCStr(script_name_ruby) : NULL;
			return cxt->eval_to_ruby(StringValueCStr(script), FIX2INT(timeout), script_name);
		});
}

static VALUE context_set_var(VALUE self, VALUE name, VALUE value) {
	return protect_ruby([&] {
		rc(self)->set_var(name, value);
		return Qnil;
	});
}

static VALUE context_gate_class(VALUE self, VALUE name, VALUE lambda) {
	return protect_ruby([&] {
		rc(self)->gate_class(name, lambda);
		return Qnil;
	});
}

static VALUE context_force_gc(VALUE self) {
	rc(self)->gc();
	return Qnil;
}

static void context_free(void* ptr) {
	delete (H8*) ptr;
}

static void context_mark(void* ptr) {
	H8* h8 = (H8*) ptr;
	h8->ruby_mark_gc();
}

namespace h8 {
VALUE context_alloc(VALUE klass) {
	H8 *h8 = new H8;
	h8->self = Data_Wrap_Struct(klass, context_mark, context_free, h8);
	return h8->self;
}
}

void init_v8() {
	v8::V8::InitializeICU();
	v8::Platform* platform = v8::platform::CreateDefaultPlatform();
	v8::V8::InitializePlatform(platform);
	v8::V8::Initialize();
}

void Init_h8(void) {
	init_v8();

	id_is_a = rb_intern("is_a?");
	id_safe_call = rb_intern("secure_call");
	id_safe_proc_call = rb_intern("safe_proc_call");
	id_delete_handler = rb_intern("delete_handler");

	VALUE h8 = rb_define_module("H8");

	context_class = rb_define_class_under(h8, "Context", rb_cObject);
	ruby_gate_class = rb_define_class_under(h8, "RubyGate", rb_cObject);
	rb_define_alloc_func(context_class, context_alloc);
	rb_define_method(context_class, "_eval", (ruby_method) context_eval, 3);
	rb_define_method(context_class, "_set_var", (ruby_method) context_set_var,
			2);
	rb_define_method(context_class, "_gate_class", (ruby_method) context_gate_class,
			2);
	rb_define_method(context_class, "javascript_gc",
			(ruby_method) context_force_gc, 0);

	value_class = rb_define_class_under(h8, "Value", rb_cObject);
	rb_define_alloc_func(value_class, rvalue_alloc);
	rb_define_method(value_class, "to_s", (ruby_method) rvalue_to_s, 0);
	rb_define_method(value_class, "to_i", (ruby_method) rvalue_to_i, 0);
	rb_define_method(value_class, "to_f", (ruby_method) rvalue_to_f, 0);
	rb_define_method(value_class, "integer?", (ruby_method) rvalue_is_int, 0);
	rb_define_method(value_class, "float?", (ruby_method) rvalue_is_float, 0);
	rb_define_method(value_class, "string?", (ruby_method) rvalue_is_string, 0);
	rb_define_method(value_class, "array?", (ruby_method) rvalue_is_array, 0);
	rb_define_method(value_class, "object?", (ruby_method) rvalue_is_object, 0);
	rb_define_method(value_class, "function?", (ruby_method) rvalue_is_function,
			0);
	rb_define_method(value_class, "undefined?",
			(ruby_method) rvalue_is_undefined, 0);
	rb_define_method(value_class, "_get_attr", (ruby_method) rvalue_get_attr,
			1);
	rb_define_method(value_class, "_get_index", (ruby_method) rvalue_get_index,
			1);
	rb_define_method(value_class, "_set_attr", (ruby_method) rvalue_set_attr,
			2);
	rb_define_method(value_class, "_call", (ruby_method) rvalue_call, 1);
	rb_define_method(value_class, "_apply", (ruby_method) rvalue_apply, 2);
	rb_define_method(value_class, "context",
			(ruby_method) rvalue_get_ruby_context, 0);

	h8_exception = rb_define_class_under(h8, "Error", rb_eStandardError);
	js_exception = rb_define_class_under(h8, "JsError", h8_exception);
	js_nested_exception = rb_define_class_under(h8, "NestedError", js_exception);
	js_timeout_exception = rb_define_class_under(h8, "TimeoutError",
			js_exception);

	VALUE u_class = rb_define_class_under(h8, "UndefinedClass", rb_cObject);
	Rundefined = rb_funcall(u_class, rb_intern("instance"), 0);
}

