#ifndef _h8_h
#define _h8_h

#include <include/v8.h>
#include <ruby.h>
#include <iostream>

using namespace v8;
using namespace std;

extern VALUE h8_exception;
extern VALUE h8_class;
extern VALUE value_class;

//#include <ruby/thread.h>

namespace h8 {

template<class T> inline void t(const T& x) {
	cout << x << endl << flush;
}

class H8 {
public:

	class Scope: public HandleScope {
		v8::Isolate::Scope isolate_scope;
		v8::Context::Scope context_scope;
		H8* rcontext;
	public:
		Scope(H8* cxt) :
				HandleScope(cxt->getIsolate()), isolate_scope(
						cxt->getIsolate()), context_scope(cxt->getContext()), rcontext(
						cxt) {
		}
	};

	static void init();

	H8() {
		isolate = Isolate::New();
		Isolate::Scope isolate_scope(isolate);
		HandleScope handle_scope(isolate);

		v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New(
				isolate);
		v8::Handle<v8::Context> context = v8::Context::New(isolate, NULL,
				global);
		persistent_context.Reset(isolate, context);
	}

	Handle<Value> eval(const char* script_utf) {
		v8::EscapableHandleScope escape(isolate);
		Local<Value> result;

		Handle<v8::String> script_source = String::NewFromUtf8(isolate,
				script_utf);
		v8::Handle<v8::Script> script;
		v8::TryCatch try_catch;
		v8::ScriptOrigin origin(String::NewFromUtf8(isolate, "eval"));

		script = v8::Script::Compile(script_source, &origin);

		if (script.IsEmpty()) {
			report_exception(try_catch);
			result = Undefined(isolate);
		} else {
			result = script->Run();
			if (try_catch.HasCaught()) {
				report_exception(try_catch);
			}
		}
		return escape.Escape(result);
	}

	VALUE eval_to_ruby(const char* script_utf) {
		// TODO: throw ruby exception on error
		return to_ruby(eval(script_utf));
	}

	Handle<Context> getContext() {
		return Local<Context>::New(isolate, persistent_context);
	}

	bool isError() const {
		return is_error;
	}

	Isolate* getIsolate() const {
		return isolate;
	}

	VALUE to_ruby(Handle<Value> value);

	v8::Local<v8::String> js(VALUE val) const {
		return js(StringValueCStr(val));
	}

	v8::Local<v8::String> js(const char* str) const {
		return v8::String::NewFromUtf8(isolate,str);
	}

	void set_var(VALUE name,VALUE value) {
		Scope scope(this);
		getContext()->Global()->Set(js(name), to_js(value));
	}

	Local<Value> to_js(VALUE ruby_value) {
		switch( TYPE(ruby_value) ) {
		case T_STRING:
			return js(ruby_value);
		case T_FIXNUM:
			return v8::Int32::New(isolate, FIX2INT(ruby_value));
		case T_FLOAT:
			return v8::Number::New(isolate, NUM2DBL(ruby_value));
		default:
			rb_raise(h8_exception, "unknown type");
			return Undefined(isolate);
		}
	}

	virtual ~H8() {
		persistent_context.Reset();
	}

private:
	friend VALUE context_alloc(VALUE klass);
	friend void rvalue_mark(void* ptr);

	Isolate *isolate;
	VALUE   self;

	void report_exception(v8::TryCatch& tc) {
		printf("\n\nERROR: eval failed\n");
	}

	Persistent<Context> persistent_context;

	bool is_error = false;
};
// Context
}


typedef VALUE (*ruby_method)(...);

#include "js_gate.h"

inline VALUE h8::H8::to_ruby(Handle<Value> value) {
	return JsGate::to_ruby(this, value);
}


#endif
