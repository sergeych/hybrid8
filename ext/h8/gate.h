#ifndef __gate_h
#define __gate_h

#include "h8.h"

namespace h8 {

class Gate {
public:

	Gate() {
	}

	template<class T>
	void set(H8 *h8, const Handle<T>& val) {
		this->h8 = h8;

		printf("RESET");
		value.Reset(h8->getIsolate(), val);
		printf("RESET done, cerating ruby object");
	}

	VALUE to_s() {
		printf("TO_S");
		H8::Scope scope(h8);
//    	Local<Value> v = Local<Value>::New(isolate, p_value);
		printf("EXT");

		String::Utf8Value res(Local<Value>::New(h8->getIsolate(), value));
		printf("GOT %s", *res);
		return *res ? rb_str_new2(*res) : Qnil;
	}

	VALUE to_i() {
//        return INT2FIX(value->IntegerValue());
		return Qnil;
	}

	VALUE is_int() {
//        return value->IsInt32() ? Qtrue : Qfalse;
		return Qnil;
	}

	VALUE is_float() {
//        return value->IsNumber() ? Qtrue : Qfalse;
		return Qnil;
	}

	VALUE is_string() {
//        return value->IsString() ? Qtrue : Qfalse;
		return Qnil;
	}

	~Gate() {
		value.Reset();
	}
private:
	H8 *h8;
	Persistent<Value> value;
};

}

#endif
