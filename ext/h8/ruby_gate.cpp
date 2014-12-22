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
	v8::Handle<v8::Object> handle = templ->NewInstance();
	handle->SetAlignedPointerInInternalField(1, RUBYGATE_ID);
	Wrap(handle);
}


void h8::RubyGate::ObjectCallback(
		const v8::FunctionCallbackInfo<v8::Value>& args) {
	v8::HandleScope scope(args.GetIsolate());
	v8::Handle<v8::Object> obj = args.This();
	RubyGate* rg = h8::ObjectWrap::Unwrap<RubyGate>(args.This());
	rg->doObjectCallback(args);
}

VALUE h8::RubyGate::rescue(VALUE me,VALUE exception_object) {
	RubyGate* gate;
	Data_Get_Struct(me, RubyGate, gate);
	gate->last_ruby_error = exception_object;
	return Qnil;
}


VALUE RubyGate::call(VALUE args) {
	VALUE callable = rb_ary_pop(args);
	return rb_proc_call (callable, args);
}

void h8::RubyGate::doObjectCallback(
		const v8::FunctionCallbackInfo<v8::Value>& args) {
	last_ruby_error = Qnil;
	unsigned n = args.Length();

	VALUE rb_args = rb_ary_new2(n+1);
	for (unsigned i = 0; i < n; i++)
		rb_ary_push(rb_args, context->to_ruby(args[i]));
	rb_ary_push(rb_args, ruby_object);

	VALUE me = Data_Wrap_Struct(ruby_gate_class, 0, 0, this);
	VALUE res = rb_rescue((ruby_method)call, rb_args, (ruby_method)rescue, me);
	if( last_ruby_error == Qnil )
		args.GetReturnValue().Set(context->to_js(res));
	else {
		Local<v8::Object> error = v8::Exception::Error(context->js("ruby exception")).As<v8::Object>();
		error->Set(context->js("source"), context->to_js(last_ruby_error));
		context->getIsolate()->ThrowException(error);
	}
}
