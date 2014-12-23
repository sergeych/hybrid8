#include "h8.h"
#include "ruby_gate.h"

void h8::JsError::raise() {
	if (has_js_exception) {
		VALUE ruby_exception;
		{
			// raising exception does longjump so we should keep all memory
			// allocation done before:
			H8::Scope scope(h8);

			Local<Object> jsx = exception().As<Object>();
			Local<Value> source = jsx->Get(h8->js("source"));
			RubyGate *rg = RubyGate::unwrap(source.As<Object>());
			if (rg) {
				// Passing thru the Ruby exception
				ruby_exception = rg->rubyObject();
			} else {
				Local<String> s = message()->Get();
				String::Utf8Value res(s->ToString());
				ruby_exception = ruby_exception = rb_exc_new2(js_exception,
						*res ? *res : "test");
				rb_iv_set(ruby_exception, "@message", h8->to_ruby(s));
				// TODO: Pass also all information from Message instance
				rb_iv_set(ruby_exception, "@source", h8->to_ruby(source));
			}
		}
		rb_exc_raise(ruby_exception);
//		}
	} else {
		rb_raise(h8_exception, "%s", reason);
	}
}

Local<Value> h8::H8::gateObject(VALUE ruby_value) {
	if ( Qtrue == rb_funcall(ruby_value, id_is_a, 1, value_class)) {
		JsGate *gate;
		Data_Get_Struct(ruby_value, JsGate, gate);
		if (gate->h8 != this) {
			throw JsError(this, "H8::Value is bound to other H8::Context");
		} else
			return gate->value();
	}
	// Generic Ruby object
	RubyGate *gate = new RubyGate(this, ruby_value);
	return gate->handle(isolate);
}

void h8::H8::ruby_mark_gc() const {
	for (chain::link *x : resources)
		((AllocatedResource*) x)->rb_mark_gc();
}

v8::Handle<v8::Value> h8::H8::eval(const char* script_utf) {
	v8::EscapableHandleScope escape(isolate);
	Local<Value> result;

	Handle<v8::String> script_source = String::NewFromUtf8(isolate, script_utf);
	v8::Handle<v8::Script> script;
	JsCatcher try_catch(this);
	v8::ScriptOrigin origin(String::NewFromUtf8(isolate, "eval"));

	script = v8::Script::Compile(script_source, &origin);

	if (script.IsEmpty()) {
		try_catch.throwIfCaught();
		result = Undefined(isolate);
	} else {
		result = script->Run();
		try_catch.throwIfCaught();
	}
	return escape.Escape(result);
}

h8::H8::~H8() {
	while (!resources.is_empty()) {
		// this should also remove it from the list:
		resources.peek_first<AllocatedResource>()->free();
	}

	persistent_context.Reset();
	isolate->Dispose();
}
