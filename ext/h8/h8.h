#ifndef _h8_h
#define _h8_h

#include <include/v8.h>
#include <ruby.h>
#include <iostream>
#include "allocated_resource.h"

using namespace v8;
using namespace std;

extern VALUE h8_exception;
extern VALUE h8_class;
extern VALUE value_class;

extern ID id_is_a;

namespace h8 {

class RubyGate;

template<class T> inline void t(const T& x) {
	cout << x << endl << flush;
}

/**
 * The exception that is raised toward ruby code, e.g. when JS code throws uncaught exception,
 * interpreter fails to cope with syntax, parameters are used in a wrong way, etc. Instead of calling
 * rb_raise() which will longjump() over all your C++ code, throw instance of JsError.
 */
class JsError : public std::exception {
public:
	JsError(const char* str_reason) {
		reason = str_reason;
	}

	/**
	 * Call it with a proper exception class and be careful - after this call no code will be executed!
	 */
	void raise(VALUE exception_class) {
		rb_raise(exception_class, "%s", reason);
	}

protected:
	const char* reason;
};

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

	H8() : self(Qnil) {
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
		return v8::String::NewFromUtf8(isolate, str);
	}

	void set_var(VALUE name, VALUE value) {
		Scope scope(this);
		getContext()->Global()->Set(js(name), to_js(value));
	}

	Local<Value> to_js(VALUE ruby_value) {
		switch (TYPE(ruby_value)) {
		case T_STRING:
			return js(ruby_value);
		case T_FIXNUM:
			return v8::Int32::New(isolate, FIX2INT(ruby_value));
		case T_FLOAT:
			return v8::Number::New(isolate, NUM2DBL(ruby_value));
		case T_DATA:
		case T_OBJECT:
			return gateObject(ruby_value);
		default:
			rb_raise(h8_exception, "can't gate to js: unknown type");
		}
		return Undefined(isolate);
	}

	Local<Value> gateObject(VALUE object);

	VALUE ruby_context() const {
		return self;
	}

	void add_resource(AllocatedResource *resource) {
		resources.push(resource);
	}

	void ruby_mark_gc() const;

	virtual ~H8();

private:
	friend VALUE h8::context_alloc(VALUE klass);

	Isolate *isolate;
	VALUE self;

	void report_exception(v8::TryCatch& tc) {
		// Todo: carry out interpreter error information (e.g. line, text)
		throw JsError("Failed to compile/execute script");
	}

	Persistent<Context> persistent_context;

	bool is_error = false;

	chain resources;
};
// Context
}

typedef VALUE (*ruby_method)(...);

#include "js_gate.h"

inline VALUE h8::H8::to_ruby(Handle<Value> value) {
	return JsGate::to_ruby(this, value);
}

#endif
