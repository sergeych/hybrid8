#include <thread>
#include <mutex>
#include <condition_variable>
#include <chrono>

#include "h8.h"
#include <ruby/thread.h>
#include "ruby_gate.h"

void h8::JsError::raise() const {
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
				Local<Message> m = message();
				Local<String> s = m->Get();
				String::Utf8Value res(s->ToString());
				ruby_exception = ruby_exception = rb_exc_new2(js_exception,
						*res ? *res : "unknown javascript exception");
				rb_iv_set(ruby_exception, "@message", h8->to_ruby(s));
				rb_iv_set(ruby_exception, "@javascript_error",
						h8->to_ruby(jsx));
			}
		}
		rb_exc_raise(ruby_exception);
//		}
	} else {
		rb_raise(h8_exception, "%s", reason);
	}
}

const char* h8::JsError::what() const noexcept {
	return reason;
}

void h8::JsTimeoutError::raise() const {
	rb_raise(js_timeout_exception, "timeout expired");
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
	if( ruby_value == Rundefined )
		return v8::Undefined(isolate);
	// Generic Ruby object
	RubyGate *gate = new RubyGate(this, ruby_value);
	return gate->handle(isolate);
}

void h8::H8::ruby_mark_gc() const {
	for (chain::link *x : resources)
		((AllocatedResource*) x)->rb_mark_gc();
}

struct CallerParams {
	h8::H8* h8;
	Handle<Script>& script;
	Local<Value>& result;
};

static void* script_caller(void* param) {
	CallerParams *cp = (CallerParams*) param;
	cp->h8->setGvlReleased(true);
	cp->result = cp->script->Run();
	return NULL;
}

static void unblock_script(void* param) {
	h8::H8* h8 = (h8::H8*) param;
	if( rb_thread_interrupted(rb_thread_current()) ) {
		printf("UNBLOCK!!!! CALLED!!! Why? %p\n", param);
		h8->setInterrupted();
		h8->getIsolate()->TerminateExecution();
	}
	else {
		puts("UBF not interrupted. why?");
	}
}

void h8::H8::invoke(v8::Handle<v8::Script> script, Local<Value>& result) {
#if 1
	CallerParams cp = { this, script, result };
	rb_interrupted = false;
	rb_thread_call_without_gvl(script_caller, &cp, NULL, NULL);
	setGvlReleased(false);
#else
	gvl_released = false;
	result = script->Run();
#endif
}

v8::Handle<v8::Value> h8::H8::eval(const char* script_utf, unsigned max_ms,const char* source_name) {
	v8::EscapableHandleScope escape(isolate);
	Local<Value> result;

	Handle<v8::String> script_source = String::NewFromUtf8(isolate, script_utf);
	v8::Handle<v8::Script> script;
	JsCatcher try_catch(this);
	if( source_name == NULL)
		source_name = "eval";
	v8::ScriptOrigin origin(String::NewFromUtf8(isolate, source_name));

	script = v8::Script::Compile(script_source, &origin);

	if (script.IsEmpty()) {
		try_catch.throwIfCaught();
		result = Undefined(isolate);
	} else {
		result = Undefined(isolate);
		if (max_ms > 0) {
			std::mutex m;
			std::condition_variable cv;
			std::thread thr(
					[&] {
						std::unique_lock<std::mutex> lock(m);
						if( std::cv_status::timeout == cv.wait_for(lock, std::chrono::milliseconds(max_ms) ) ) {
							isolate->TerminateExecution();
						}
					});
			invoke(script, result);
			cv.notify_all();
			thr.join();
		} else {
			invoke(script, result);
		}
		try_catch.throwIfCaught();
	}
	return escape.Escape(result);
}

h8::H8::~H8() {
	{
		Scope s(this);
		while (!resources.is_empty()) {
			// this should also remove it from the list:
			resources.peek_first<AllocatedResource>()->free();
		}
		persistent_context.Reset();
	}
	isolate->Dispose();
}
