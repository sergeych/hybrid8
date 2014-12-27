#include "h8.h"
#include "ruby_gate.h"
#include <ruby.h>

using namespace h8;

h8::RubyGate::RubyGate(H8* _context, VALUE object) :
		context(_context), ruby_object(object), next(0), prev(0) {
	v8::HandleScope scope(context->getIsolate());
//        	printf("Ruby object gate constructor\n");
	context->add_resource(this);

	v8::Local<v8::ObjectTemplate> templ = ObjectTemplate::New();
	templ->SetInternalFieldCount(2);
	templ->SetCallAsFunctionHandler(&ObjectCallback);

	templ->SetNamedPropertyHandler(RubyGate::mapGet, RubyGate::mapSet);
	templ->SetIndexedPropertyHandler(RubyGate::indexGet,RubyGate::indexSet);

	v8::Handle<v8::Object> handle = templ->NewInstance();
	handle->SetAlignedPointerInInternalField(1, RUBYGATE_ID);
	Wrap(handle);
}

void h8::RubyGate::mapGet(Local<String> name,
		const PropertyCallbackInfo<Value> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->getProperty(name, info);
}

void h8::RubyGate::mapSet(Local<String> name,
		Local<Value> value,
		const PropertyCallbackInfo<Value> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->setProperty(name, value, info);
}

void h8::RubyGate::indexGet(uint32_t index,
		const PropertyCallbackInfo<Value> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->getIndex(index, info);
}

void h8::RubyGate::indexSet(uint32_t index,
		Local<Value> value,
		const PropertyCallbackInfo<Value> &info) {
	RubyGate *rg = RubyGate::unwrap(info.This());
	assert(rg != 0);
	rg->setIndex(index, value, info);
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
	return rb_proc_call(callable, args);
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
	last_ruby_error = Qnil;
	VALUE me = Data_Wrap_Struct(ruby_gate_class, 0, 0, this);
	VALUE res = rb_rescue((ruby_method) (call), rb_args,
			(ruby_method) (rescue_callback), me);
	if (last_ruby_error == Qnil)
		block(res);
	else
		throw_js();
}

void h8::RubyGate::doObjectCallback(
		const v8::FunctionCallbackInfo<v8::Value>& args) {

	VALUE rb_args = ruby_args(args, 1);
	rb_ary_push(rb_args, ruby_object);
	return rescued_call(rb_args, call, [&] (VALUE res) {
		args.GetReturnValue().Set(context->to_js(res));
	});
}

void h8::RubyGate::getProperty(Local<String> name,
		const PropertyCallbackInfo<Value> &info) {
	VALUE rb_args = rb_ary_new2(2);
	rb_ary_push(rb_args, ruby_object);
	rb_ary_push(rb_args, context->to_ruby(name));
	return rescued_call(rb_args, secure_call, [&] (VALUE res) {
		info.GetReturnValue().Set(context->to_js(res));
		});
}

void h8::RubyGate::setProperty(Local<String> name,
		Local<Value> value,
		const PropertyCallbackInfo<Value> &info) {
	VALUE rb_args = rb_ary_new2(3);
	rb_ary_push(rb_args, context->to_ruby(value));
	rb_ary_push(rb_args, ruby_object);
	VALUE method = context->to_ruby(name);
	method = rb_str_cat2(method, "=");
	rb_ary_push(rb_args, method);
	return rescued_call(rb_args, secure_call, [&] (VALUE res) {
		info.GetReturnValue().Set(context->to_js(res));
		});
}

void h8::RubyGate::getIndex(uint32_t index,
		const PropertyCallbackInfo<Value> &info) {
	VALUE rb_args = rb_ary_new2(3);
	rb_ary_push(rb_args, INT2FIX(index));
	rb_ary_push(rb_args, ruby_object);
	rb_ary_push(rb_args, rb_str_new2("[]"));
	return rescued_call(rb_args, secure_call, [&] (VALUE res) {
		info.GetReturnValue().Set(context->to_js(res));
		});
}

void h8::RubyGate::setIndex(uint32_t index,
		Local<Value> value,
		const PropertyCallbackInfo<Value> &info) {
	VALUE rb_args = rb_ary_new2(4);
	rb_ary_push(rb_args, INT2FIX(index));
	rb_ary_push(rb_args, context->to_ruby(value));
	rb_ary_push(rb_args, ruby_object);
	rb_ary_push(rb_args, rb_str_new2("[]="));
	return rescued_call(rb_args, secure_call, [&] (VALUE res) {
		info.GetReturnValue().Set(context->to_js(res));
		});
}

