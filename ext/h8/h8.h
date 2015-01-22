#ifndef _h8_h
#define _h8_h

#include <include/v8.h>
#include <ruby.h>
#include <iostream>
#include <exception>
#include <map>

#include "allocated_resource.h"
#include "js_catcher.h"

using namespace v8;
using namespace std;

extern VALUE h8_exception, js_exception, js_timeout_exception;
extern VALUE context_class;
extern VALUE value_class;
extern VALUE ruby_gate_class;
extern VALUE Rundefined;

extern ID id_is_a, id_safe_call, id_safe_proc_call, id_delete_handler;

VALUE protect_ruby(const std::function<VALUE()> &block);

namespace h8 {

/// Allocate ruby H8::Context class (wrapper for h8::H8), ruby utility function
/// shold be declared as friend
VALUE context_alloc(VALUE klass);

class RubyGate;
class H8;

template<class T> inline void t(const T& x) {
	cout << x << endl << flush;
}

/**
 * The exception that is raised toward ruby code, e.g. when JS code throws uncaught exception,
 * interpreter fails to cope with syntax, parameters are used in a wrong way, etc. Instead of calling
 * rb_raise() which will longjump() over all your C++ code, throw instance of JsError.
 */
class JsError: public std::exception {
public:
	JsError(H8* h8, const char* str_reason) :
			h8(h8), has_js_exception(false) {
		reason = str_reason;
	}

	JsError(H8* h8, Local<Message> message, Local<Value> exception);

	/**
	 * Call it with a proper exception class and be careful - after this call no code will be executed!
	 */
	virtual void raise() const;

	Local<Message> message() const;

	Local<Value> exception() const;

	Local<Value> stacktrace() const;

	virtual const char* what() const noexcept;

	virtual ~JsError() {
		_message.Reset();
		_exception.Reset();
	}
protected:
	const char* reason;
	bool has_js_exception;
	H8 *h8;
	v8::Persistent<v8::Message, v8::CopyablePersistentTraits<v8::Message>> _message;
	v8::Persistent<v8::Value, v8::CopyablePersistentTraits<v8::Value>> _exception;
};

class JsTimeoutError: public JsError {
public:
	JsTimeoutError(H8* h8) :
			JsError(h8, NULL) {
	}
	virtual void raise() const;
};

class H8 {
public:

	class Scope {
		Locker locker;
		Isolate::Scope isolate_scope;
		HandleScope handle_scope;
		Context::Scope context_scope;

		H8* rcontext;

	public:
		Scope(H8* cxt) :
				locker(cxt->getIsolate()), handle_scope(cxt->getIsolate()), isolate_scope(
						cxt->getIsolate()), context_scope(cxt->getContext()), rcontext(
						cxt) {
		}
	};

	static void init();

	H8();

	/**
	 * Evaluate javascript.
	 *
	 * \param script_utf the null-terminated script string in utf8 endcoding
	 * \param max_ms if set, then script maximum execution time will be limited
	 * 				 to this value, JsTimeoutError will be thrown if exceeded
	 * \return the value returned by the script.
	 */
	Handle<Value> eval(const char* script_utf, unsigned max_ms = 0,
			const char* script_name = NULL);

	VALUE eval_to_ruby(const char* script_utf, int timeout = 0,
			const char* script_name = NULL) {
		// TODO: throw ruby exception on error
		return to_ruby(eval(script_utf, timeout, script_name));
	}

	Handle<Context> getContext() {
		return Local<Context>::New(isolate, persistent_context);
	}

	Handle<FunctionTemplate> getGateFunctionTemplate() {
		return Local<FunctionTemplate>::New(isolate, gate_function_template);
	}

	Handle<Function> getGateFunction() {
		return Local<Function>::New(isolate, gate_function);
	}

	bool isError() const {
		return is_error;
	}

	Isolate* getIsolate() const {
		return isolate;
	}

	void gate_class(VALUE name, VALUE proc);

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

	void gc() {
//		puts("H8 GC");
		while (!isolate->IdleNotification(500)) {
		}
	}

	Local<Value> to_js(VALUE ruby_value) {
		switch (TYPE(ruby_value)) {
		case T_STRING:
			return js(ruby_value);
		case T_FIXNUM:
			return v8::Int32::New(isolate, FIX2INT(ruby_value));
		case T_FLOAT:
			return v8::Number::New(isolate, NUM2DBL(ruby_value));
		case T_UNDEF:
			return v8::Undefined(isolate);
		case T_NIL:
			return v8::Null(isolate);
		case T_TRUE:
			return v8::True(isolate);
		case T_FALSE:
			return v8::False(isolate);
		case T_ARRAY:
		case T_HASH:
		case T_DATA:
		case T_OBJECT:
		case T_CLASS:
			return gateObject(ruby_value);
		default:
			VALUE msg = rb_str_new2("can't gate to js (unknown): ");
			rb_str_append(msg, rb_any_to_s(ruby_value));
			throw JsError(this, StringValueCStr(msg));
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

	bool isGvlReleased() const noexcept {
		return gvl_released;
	}

	void setGvlReleased(bool state) noexcept {
		gvl_released = state;
	}

	void setInterrupted() {
		rb_interrupted = true;
	}

	bool isInterrupted() const {
		return rb_interrupted;
	}

	void register_ruby_gate(RubyGate* gate);
	void unregister_ruby_gate(RubyGate* gate);
	RubyGate *find_gate(VALUE rb_object);

	virtual ~H8();

private:
	friend VALUE h8::context_alloc(VALUE klass);
	void invoke(v8::Handle<v8::Script> script, Local<Value>& result);
	static void SetupGateTemplate(const Local<ObjectTemplate>& templ);

	Isolate *isolate;
	VALUE self;

	Persistent<Context> persistent_context;
	Persistent<FunctionTemplate> gate_function_template;
	Persistent<Function> gate_function;

	bool is_error = false;
	bool gvl_released = false;
	bool rb_interrupted = false;

	chain resources;
	std::map<VALUE,RubyGate*> id_map;
};
// Context
}

typedef VALUE (*ruby_method)(...);

#include "js_gate.h"

inline VALUE h8::H8::to_ruby(Handle<Value> value) {
	return JsGate::to_ruby(this, value);
}

inline h8::JsError::JsError(H8* h8, Local<Message> message,
		Local<Value> exception) :
		h8(h8), _message(h8->getIsolate(), message), _exception(
				h8->getIsolate(), exception), has_js_exception(true), reason(
		NULL) {
}

inline Local<Message> h8::JsError::message() const {
	return Local<Message>::New(h8->getIsolate(), _message);
}

inline Local<Value> h8::JsError::exception() const {
	return Local<Value>::New(h8->getIsolate(), _exception);
}

#endif
