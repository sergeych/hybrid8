#ifndef _h8_h
#define _h8_h

#include <include/v8.h>
#include <ruby.h>
#include <iostream>

using namespace v8;
using namespace std;

//#include <ruby/thread.h>

namespace h8 {

template<class T> inline void t(const T& x) {
	cout << x << endl;
}

class H8 {
public:

	class Scope: public HandleScope {
		v8::Isolate::Scope isolate_scope;
		v8::Context::Scope context_scope;
		v8::EscapableHandleScope escapable_scope;
		H8* rcontext;
	public:
		Scope(H8* cxt) :
				HandleScope(cxt->getIsolate()), isolate_scope(
						cxt->getIsolate()), context_scope(cxt->getContext()), rcontext(
						cxt), escapable_scope(cxt->getIsolate()) {
		}

		template<class T>
		Local<T> escape(Local<T> value) {
			return escapable_scope.Escape(value);
		}

	};

	static void init();

	H8() {
		isolate = Isolate::New();
		Isolate::Scope isolate_scope(isolate);
		HandleScope handle_scope(isolate);

		t("i");
		// Create a template for the global object.
		v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New(
				isolate);

		// Create a new execution environment containing the built-in
		// functions
		v8::Handle<v8::Context> context = v8::Context::New(isolate, NULL,
				global);
		persistent_context.Reset(isolate, context);
	}

	Handle<Value> eval(const char* script_utf) {
//		H8::Scope scope(this);
		v8::EscapableHandleScope escope(isolate);
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
//			lastResult.Reset(isolate, result);
			if (try_catch.HasCaught()) {
				report_exception(try_catch);
			}
		}
//		String::Utf8Value u(result);
//		printf("Eval: exctracted res: %s\n", *u);
		return escope.Escape(result);
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

	virtual ~H8() {
		persistent_context.Reset();
	}

//	v8::Handle<v8::Value> getLastResult() {
//		return Local<Value>::New(isolate, lastResult);
//	}

private:
	Isolate *isolate;
	void report_exception(v8::TryCatch& tc) {
		printf("\n\nERROR: eval failed\n");
	}

	Persistent<Context> persistent_context;

	Persistent<Value, CopyablePersistentTraits<v8::Value>> lastResult;
	bool is_error = false;
};
// Context
}

extern VALUE h8_exception;
extern VALUE h8_class;

typedef VALUE (*ruby_method)(...);

#include "gate.h"

#endif
