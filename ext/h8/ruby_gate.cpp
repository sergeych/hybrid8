#include <functional>
#include "h8.h"
#include "ruby_gate.h"
#include <ruby.h>
#include <ruby/thread.h>

using namespace h8;

static void* unblock_caller(void *param) {
	const std::function<void(void)>* pblock =
			(const std::function<void(void)>*) param;
	(*pblock)();
	return NULL;
}

static void with_gvl(H8 *h8, const std::function<void(void)> &block) {
	if (h8->isGvlReleased()) {
		h8->setGvlReleased(false);
		rb_thread_call_with_gvl(unblock_caller, (void*) &block);
		h8->setGvlReleased(true);
	} else
		block();
}

static void with_gvl(RubyGate *gate, const std::function<void(void)> &block) {
	with_gvl(gate->getH8(), block);
}

void h8::RubyGate::ClassGateConstructor(
		const v8::FunctionCallbackInfo<Value>& args) {
	Isolate *isolate = args.GetIsolate();
	H8* h8 = (H8*) isolate->GetData(0);
	assert(!args.Data().IsEmpty());

	RubyGate *lambda = RubyGate::unwrap(args.Data().As<Object>());
	assert(lambda != 0);

	with_gvl(h8, [&] {
		VALUE rb_args = ruby_args(h8, args, 2);
		rb_ary_push(rb_args, h8->ruby_context());
		rb_ary_push(rb_args, lambda->ruby_object);
		// Object creating ruby code can raise exceptions:
			lambda->rescued_call(
					rb_args,
					call,
					[&] (VALUE res) {
						new RubyGate(h8, args.This(), res);
					});
		});
	args.GetReturnValue().Set(args.This());
}

void h8::RubyGate::GateConstructor(
		const v8::FunctionCallbackInfo<Value>& args) {
	Isolate *isolate = args.GetIsolate();
	H8* h8 = (H8*) isolate->GetData(0);
	assert(args.Length() == 1);
	Local<Value> val = args[0];
	VALUE ruby_object = Qnil;

	assert(val->IsExternal());
	ruby_object = (VALUE) val.As<External>()->Value(); // External::Cast(*val)->Value();

	new RubyGate(h8, args.This(), ruby_object);
	args.GetReturnValue().Set(args.This());
}

h8::RubyGate::RubyGate(H8* _context, Handle<Object> instance, VALUE object) :
		context(_context), ruby_object(object), next(0), prev(0) {
	v8::HandleScope scope(context->getIsolate());
	context->register_ruby_gate(this);
	instance->SetAlignedPointerInInternalField(1, RUBYGATE_ID);
	Wrap(instance);
}

void h8::RubyGate::mapGet(Local<String> name,
		const PropertyCallbackInfo<Value> &info) {
	v8::String::Utf8Value val(name);
	if (strcmp(*val, "prototype") == 0) {
		info.GetReturnValue().Set(info.This()->GetPrototype());
		return;
	}

	Local<Value> loc = info.This()->GetRealNamedPropertyInPrototypeChain(name);
	if (!loc.IsEmpty())
		info.GetReturnValue().Set(loc);
	else {
		RubyGate *rg = RubyGate::unwrap(info.This());
		assert(rg != 0);
		rg->getProperty(name, info);
	}
}

void h8::RubyGate::mapSet(Local<String> name, Local<Value> value,
		const PropertyCallbackInfo<Value> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->setProperty(name, value, info);
}

void h8::RubyGate::mapDelete(Local<String> name,
		const PropertyCallbackInfo<Boolean> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->deleteProperty(name, info);
}

void h8::RubyGate::mapQuery(Local<String> name,
		const PropertyCallbackInfo<Integer>& info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->queryProperty(name, info);
}

void h8::RubyGate::mapEnumerate(const PropertyCallbackInfo<Array> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->enumerateProperties(info);
}

void h8::RubyGate::indexGet(uint32_t index,
		const PropertyCallbackInfo<Value> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->getIndex(index, info);
}

void h8::RubyGate::indexSet(uint32_t index, Local<Value> value,
		const PropertyCallbackInfo<Value> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->setIndex(index, value, info);
}

void h8::RubyGate::indexEnumerate(const PropertyCallbackInfo<Array>& info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->enumerateProperties(info);
}

void h8::RubyGate::ObjectCallback(
		const v8::FunctionCallbackInfo<v8::Value>& args) {
	v8::HandleScope scope(args.GetIsolate());
	v8::Handle<v8::Object> obj = args.This();
	RubyGate* rg = h8::ObjectWrap::Unwrap<RubyGate>(args.This());
	rg->doObjectCallback(args);
}

VALUE h8::RubyGate::rescue_callback(VALUE me, VALUE exception_object) {
	RubyGate* gate;
	Data_Get_Struct(me, RubyGate, gate);
	gate->last_ruby_error = exception_object;
	return Qnil;
}

VALUE RubyGate::call(VALUE args) {
	VALUE callable = rb_ary_pop(args);
	VALUE context = rb_ary_pop(args);
	VALUE res = rb_funcall(context, id_safe_proc_call, 2, callable, args);
	return res;
}

VALUE RubyGate::ruby_delete_handler(VALUE args) {
	VALUE method = rb_ary_pop(args);
	return rb_funcall(context_class, id_delete_handler, 2, method, args);
}

VALUE RubyGate::secure_call(VALUE args) {
	VALUE method = rb_ary_pop(args);
	VALUE receiver = rb_ary_pop(args);
	return rb_funcall(context_class, id_safe_call, 3, receiver, method, args);
}

void h8::RubyGate::throw_js() {
	Local<v8::Object> error = v8::Exception::Error(
			context->js("ruby exception")).As<v8::Object>();
	error->Set(context->js("source"), context->to_js(last_ruby_error));
	context->getIsolate()->ThrowException(error);
}

void h8::RubyGate::rescued_call(VALUE rb_args, VALUE (*call)(VALUE),
		const std::function<void(VALUE)> &block) {
	VALUE res;
	{
		last_ruby_error = Qnil;
		VALUE me = Data_Wrap_Struct(ruby_gate_class, 0, 0, this);
		Unlocker u(context->getIsolate());
		res = rb_rescue((ruby_method) (call), rb_args,
				(ruby_method) (rescue_callback), me);
	}

	if (last_ruby_error == Qnil) {
		// This could be removed later, as normally here shouldn't be any
		// exceptions...
		try {
			block(res);
		} catch (JsError& e) {
			Local<v8::Object> error = v8::Exception::Error(
					context->js(e.what())).As<v8::Object>();
			context->getIsolate()->ThrowException(error);
		} catch (...) {
			Local<v8::Object> error =
					v8::Exception::Error(
							context->js("unknown exception (inner bug)")).As<
							v8::Object>();
			context->getIsolate()->ThrowException(error);
		}
	} else {
		throw_js();
	}
}

void h8::RubyGate::doObjectCallback(
		const v8::FunctionCallbackInfo<v8::Value>& args) {
	with_gvl(this, [&] {
		VALUE rb_args = ruby_args(context, args, 1);
		rb_ary_push(rb_args, context->ruby_context());
		rb_ary_push(rb_args, ruby_object);
		rescued_call(rb_args, call, [&] (VALUE res) {
					if( res == ruby_object )
					args.GetReturnValue().Set(args.This());
					else
					args.GetReturnValue().Set(context->to_js(res));
				});
	});
}

void h8::RubyGate::getProperty(Local<String> name,
		const PropertyCallbackInfo<Value> &info) {
	with_gvl(this, [&] {
		VALUE rb_args = rb_ary_new2(2);
		rb_ary_push(rb_args, ruby_object);
		rb_ary_push(rb_args, context->to_ruby(name));
		rescued_call(rb_args, secure_call, [&] (VALUE res) {
					if( res == ruby_object )
					info.GetReturnValue().Set(info.This());
					else
					info.GetReturnValue().Set(context->to_js(res));
				});
	});
}

void h8::RubyGate::setProperty(Local<String> name, Local<Value> value,
		const PropertyCallbackInfo<Value> &info) {
	with_gvl(this, [&] {
		VALUE rb_args = rb_ary_new2(3);
		rb_ary_push(rb_args, context->to_ruby(value)); // value
			rb_ary_push(rb_args, ruby_object);// object
			VALUE method = context->to_ruby(name);
			method = rb_str_cat2(method, "=");
			rb_ary_push(rb_args, method);// name=
			rescued_call(rb_args, secure_call, [&] (VALUE res) {
						info.GetReturnValue().Set(context->to_js(res));
					});
		});
}

void h8::RubyGate::deleteProperty(Local<String> name,
		const PropertyCallbackInfo<Boolean> &info) {
	with_gvl(this, [&] {
		VALUE rb_args = rb_ary_new2(2);
		rb_ary_push(rb_args, context->to_ruby(name));	// name
			rb_ary_push(rb_args, ruby_object);// object

			rescued_call(rb_args, ruby_delete_handler, [&] (VALUE res) {
						auto success = Boolean::New(isolate(), res == Qnil ? false : true );
						info.GetReturnValue().Set(success);
					});
		});
}

void h8::RubyGate::enumerateProperties(
		const PropertyCallbackInfo<Array>& info) {
	with_gvl(this,
			[&] {
				VALUE rb_args = rb_ary_new2(2);
				rb_ary_push(rb_args, ruby_object);
				rb_ary_push(rb_args, rb_str_new2("__js_enumerate"));
				rescued_call(rb_args, secure_call, [&] (VALUE res) {
							int len = (int) RARRAY_LEN(res);
							v8::Handle<Array> a = v8::Array::New(context->getIsolate(), len);
							for(int i=0; i<len; i++) {
								a->Set(i, context->to_js(rb_ary_entry(res, i)));
							}
							info.GetReturnValue().Set(a);
						});
			});
}

void h8::RubyGate::queryProperty(Local<String> name,
		const PropertyCallbackInfo<Integer>& info) {
	with_gvl(this,
			[&] {
				VALUE rb_args = rb_ary_new2(2);
				rb_ary_push(rb_args, context->to_ruby(name));
				rb_ary_push(rb_args, ruby_object);
				rb_ary_push(rb_args, rb_str_new2("!__js_has_property"));
				rescued_call(rb_args, secure_call, [&] (VALUE res) {
							if( res != Qnil && res != Qfalse) {
								info.GetReturnValue().Set(Integer::New(context->getIsolate(), v8::None));
							}
						});
			});
}

void h8::RubyGate::getIndex(uint32_t index,
		const PropertyCallbackInfo<Value> &info) {
	with_gvl(this, [&] {
		VALUE rb_args = rb_ary_new2(3);
		rb_ary_push(rb_args, INT2FIX(index));
		rb_ary_push(rb_args, ruby_object);
		rb_ary_push(rb_args, rb_str_new2("[]"));
		rescued_call(rb_args, secure_call, [&] (VALUE res) {
					info.GetReturnValue().Set(context->to_js(res));
				});
	});
}

void h8::RubyGate::setIndex(uint32_t index, Local<Value> value,
		const PropertyCallbackInfo<Value> &info) {
	with_gvl(this, [&] {
		VALUE rb_args = rb_ary_new2(4);
		rb_ary_push(rb_args, INT2FIX(index));
		rb_ary_push(rb_args, context->to_ruby(value));
		rb_ary_push(rb_args, ruby_object);
		rb_ary_push(rb_args, rb_str_new2("[]="));
		rescued_call(rb_args, secure_call, [&] (VALUE res) {
					info.GetReturnValue().Set(context->to_js(res));
				});
	});
}

