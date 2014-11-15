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
		persistent_value.Reset(h8->getIsolate(), val);
	}

	VALUE to_s() {
		H8::Scope scope(h8);
		String::Utf8Value res(value());
		return *res ? rb_str_new2(*res) : Qnil;
	}

	VALUE to_i() {
		H8::Scope scope(h8);
        return INT2FIX(value()->IntegerValue());
	}

	VALUE is_int() {
		H8::Scope scope(h8);
        return value()->IsInt32() ? Qtrue : Qfalse;
	}

	VALUE is_float() {
		H8::Scope scope(h8);
        return value()->IsNumber() ? Qtrue : Qfalse;
	}

	VALUE is_string() {
		H8::Scope scope(h8);
        return value()->IsString() ? Qtrue : Qfalse;
	}

	~Gate() {
		persistent_value.Reset();
	}

	Local<Value> value() const {
		return Local<Value>::New(h8->getIsolate(), persistent_value);
	}

	Isolate* isolate() {
		return h8->getIsolate();
	}

private:
	H8 *h8;
	Persistent<Value> persistent_value;
};

}

#endif
