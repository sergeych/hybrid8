#include "ruby_gate.h"

void h8::RubyGate::ObjectCallback(
		const v8::FunctionCallbackInfo<v8::Value>& args) {
	v8::HandleScope scope(args.GetIsolate());
	v8::Handle<v8::Object> obj = args.This();
	RubyGate* rg = h8::ObjectWrap::Unwrap<RubyGate>(args.This());
	rg->doObjectCallback(args);
}

void h8::RubyGate::doObjectCallback(
		const v8::FunctionCallbackInfo<v8::Value>& args) {
	unsigned n = args.Length();
	VALUE rb_args = rb_ary_new2(n);
	for (unsigned i = 0; i < n; i++)
		rb_ary_push(rb_args, context->to_ruby(args[i]));

	VALUE res = rb_proc_call (ruby_object, rb_args);
	args.GetReturnValue().Set(context->to_js(res));
}

