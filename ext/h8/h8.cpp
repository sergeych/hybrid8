#include <h8.h>
#include <include/libplatform/libplatform.h>

using namespace h8;

extern "C" {
void Init_h8(void);
}

VALUE h8_exception;
VALUE context_class;
VALUE rvalue_class;

static void rvalue_free(void* ptr) {
	delete (RValue*) ptr;
}

static VALUE rvalue_alloc(VALUE klass) {
	return Data_Wrap_Struct(klass, 0, rvalue_free, new RValue);
}

inline RValue* rv(VALUE self) {
    RValue *pRValue;
    Data_Get_Struct(self, RValue, pRValue);
    return pRValue;
}

static VALUE rvalue_to_s(VALUE self) {
    return rv(self)->to_s();
}

static VALUE rvalue_to_i(VALUE self) {
    return rv(self)->to_i();
}

static VALUE rvalue_is_int(VALUE self) {
    return rv(self)->is_int();
}

static VALUE rvalue_is_float(VALUE self) {
    return rv(self)->is_float();
}

static VALUE rvalue_is_string(VALUE self) {
    return rv(self)->is_string();
}

inline RContext* rc(VALUE self) {
    RContext *prcxt;
    Data_Get_Struct(self, RContext, prcxt);
    return prcxt;
}

static VALUE context_set_instance(VALUE self,VALUE name,VALUE instance) {
    return Qnil;
}


void test1(Isolate* isolate) {
	EscapableHandleScope scope(isolate);
	cout << "111" << endl;
}

static VALUE context_eval(VALUE self,VALUE script) {

	RContext* cxt = rc(self);
	Isolate* isolate = cxt->getIsolate();

	Isolate::Scope is(isolate);
	HandleScope scope(isolate);

    Handle<Value> result;
    cxt->eval(StringValueCStr(script));
    cout << "Eval done..." << endl;

//    String::Utf8Value u(Local<Value>::New(isolate, cxt->getLastResult()));
//    cout << "extracted low!"<< endl;
//	cout << "Extracted utf" << *u << endl;



    if( cxt->isError() )
        return Qnil;

	return Qnil;
//    VALUE rvalue = rb_class_new_instance(0, NULL, rvalue_class);
//    RValue *pValue;
//    Data_Get_Struct(rvalue, RValue, pValue);
//    pValue->set(cxt, result);
//
//    return rvalue;
}

static void context_free(void* ptr) {
	delete (RContext*) ptr;
}

static VALUE context_alloc(VALUE klass) {
	return Data_Wrap_Struct(klass, 0, context_free, new RContext);
}


void init_v8() {
    v8::V8::InitializeICU();
    v8::Platform* platform = v8::platform::CreateDefaultPlatform();
    v8::V8::InitializePlatform(platform);
    v8::V8::Initialize();
}

void Init_h8(void) {
	init_v8();

    VALUE h8 = rb_define_module("H8");

    context_class = rb_define_class_under(h8, "Context", rb_cObject);
    rb_define_alloc_func(context_class, context_alloc);
    rb_define_method(context_class, "eval", (ruby_method) context_eval, 1);

    rvalue_class = rb_define_class_under(h8, "Value", rb_cObject);
    rb_define_alloc_func(rvalue_class, rvalue_alloc);
    rb_define_method(rvalue_class, "to_s", (ruby_method) rvalue_to_s, 0);
    rb_define_method(rvalue_class, "to_i", (ruby_method) rvalue_to_i, 0);
    rb_define_method(rvalue_class, "integer?", (ruby_method) rvalue_is_int, 0);
    rb_define_method(rvalue_class, "float?", (ruby_method) rvalue_is_float, 0);
    rb_define_method(rvalue_class, "string?", (ruby_method) rvalue_is_string, 0);


    h8_exception = rb_define_class_under(h8, "Error",rb_eStandardError);

}
