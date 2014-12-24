#ifndef __ruby_gate_h
#define __ruby_gate_h

#include <exception>
#include <functional>

#include "h8.h"
#include "object_wrap.h"
#include "allocated_resource.h"

namespace h8 {

#define RUBYGATE_ID ((void*)0xF0200)

/**
 * Gate a generic ruby object to Javascript context and retain it for
 * the lifetime of the javascript object
 */
class RubyGate: public ObjectWrap, public AllocatedResource {
public:
	RubyGate(H8* _context, VALUE object);

	/**
	 * Check the handle and unwrap the RubyGate if it is wrapped
	 * @return wrapped RubyGate* or 0
	 */
	static RubyGate* unwrap(v8::Handle<v8::Object> handle) {
		if (handle->InternalFieldCount() == 2
				&& handle->GetAlignedPointerFromInternalField(1) == RUBYGATE_ID) {
			return ObjectWrap::Unwrap<RubyGate>(handle);
		}
		return 0;
	}

	void setRubyInstance(VALUE instance) {
		this->ruby_object = instance;
	}

	virtual void rb_mark_gc() {
		rb_gc_mark(ruby_object);
	}

	virtual void free() {
		AllocatedResource::free();
		persistent().ClearWeak();
		persistent().Reset();
		delete this;
	}

	VALUE rubyObject() const {
		return ruby_object;
	}

	virtual ~RubyGate() {
	}

protected:
	/**
	 * Perform rb_rescue call to 'call' callback, and invoke block with value returned by callback
	 * unless a ruby exception is caught, in which a correct JsError is thrown.
	 */
	void rescued_call(VALUE rb_args, VALUE (*call)(VALUE),const std::function<void(VALUE)> &block);

	/**
	 * Convert some v8 parameters-like object to ruby arguments array, allocating
	 * extra slots in array if need
	 */
	template <class T>
	VALUE ruby_args(const T& args, unsigned extras = 0) {
		unsigned n = args.Length();
		VALUE rb_args = rb_ary_new2(n+extras);
		for (unsigned i = 0; i < n; i++)
			rb_ary_push(rb_args, context->to_ruby(args[i]));
		return rb_args;
	}


	/**
	 * Ruby callable callback for rb_rescue and like. Args [0..-2] are call arguments,
	 * last arg[-1] should be a callable to perform call with (for performance
	 * reasons it should be the last).
	 */
	static VALUE call(VALUE args);

	/**
	 * Call ruby method via H8::Context#secure_call
	 */
	static VALUE secure_call(VALUE args);

	/**
	 * callback for rb_rescue. Sets last_ruby_error.
	 */
	static VALUE rescue_callback(VALUE me,VALUE exception_object);

	void getProperty(Local<String> name, const PropertyCallbackInfo<Value> &info);
	void setProperty(Local<String> name, Local<Value> value,const PropertyCallbackInfo<Value> &info);
private:

	void doObjectCallback(const v8::FunctionCallbackInfo<v8::Value>& args);

	static void ObjectCallback(const v8::FunctionCallbackInfo<v8::Value>& args);
	static void mapGet(Local<String> name, const PropertyCallbackInfo<Value> &info);
	static void mapSet(Local<String> name, Local<Value> value,const PropertyCallbackInfo<Value> &info);

	void throw_js();


	friend class H8;

	H8 *context;
	VALUE ruby_object = Qnil;
	VALUE last_ruby_error = Qnil;

	RubyGate *next, *prev;
};
}

#endif
