#ifndef __js_gate_h
#define __js_gate_h

#include "h8.h"

using namespace v8;

namespace h8 {

/**
 * Interface to anything that could be converted to a Javascipt object. Provides common helpers.
 */
class JsValue {
public:
	virtual Local<Value> value() const = 0;

	Local<Object> object() const {
		return value()->ToObject();
	}

	virtual Isolate* isolate() = 0;
};


/**
 * Gates JS object to ruby environment. Holds persistent reference to the source js object until
 * ruby object is recycled (then frees it). Note that this ruby object is not meant to be kept alive
 * by the H8 instance, instead, its owner should.
 *
 * Methods of this class do not need the H8::Scope, they create one internally.
 */
class JsGate : public JsValue {
public:
	/**
	 * Used in the ruby allocator. Do not call unless you know what you do.
	 */
	JsGate() {
	}

	/**
	 * Return Ruby object that gates specified Handled javascript object. Ruby object
	 * locks permanently value until get recycled.
	 */
	template <class T>
	static VALUE to_ruby(H8* h8, const Handle<T>& value) {
	    JsGate *gate;
	    VALUE ruby_gate = rb_class_new_instance(0, NULL, value_class);
	    Data_Get_Struct(ruby_gate, JsGate, gate);
	    gate->set(h8, value);
	    return ruby_gate;
	}

	/**
	 * Reset gate to the specified handle.
	 */
	template<class T>
	void set(H8 *h8, const Handle<T>& val) {
		this->h8 = h8;
		persistent_value.Reset(h8->getIsolate(), val);
	}

	/**
	 * Get ruby string representation
	 */
	VALUE to_s() {
		H8::Scope scope(h8);
		String::Utf8Value res(value());
		return *res ? rb_str_new2(*res) : Qnil;
	}

	/**
	 * Get ruby integer representation (FIXNUM)
	 */
	VALUE to_i() {
		H8::Scope scope(h8);
        return INT2FIX(value()->IntegerValue());
	}

	/**
	 * Get ruby Float representation (FIXNUM)
	 */
	VALUE to_f() {
		H8::Scope scope(h8);
        return DBL2NUM(value()->NumberValue());
	}

	/**
	 * @return true if the object is a primitive integer
	 */
	VALUE is_int() {
		H8::Scope scope(h8);
        return value()->IsInt32() ? Qtrue : Qfalse;
	}

	/**
	 * @return true if the object is a primitive float
	 */
	VALUE is_float() {
		H8::Scope scope(h8);
        return value()->IsNumber() ? Qtrue : Qfalse;
	}

	/**
	 * @return true if the object is an array
	 */
	VALUE is_array() {
		H8::Scope scope(h8);
        return value()->IsArray() ? Qtrue : Qfalse;
	}

	/**
	 * @return true if the object is an object
	 */
	VALUE is_object() {
		H8::Scope scope(h8);
        return value()->IsObject() ? Qtrue : Qfalse;
	}

	/**
	 * Retreive JS object attribute and convert it to the ruby wrapper
	 * of the new JsGate instace.
	 */
	VALUE get_attribute(VALUE name) {
		H8::Scope scope(h8);
		Local<Value> v8_name = v8::String::NewFromUtf8(isolate(), StringValueCStr(name));
		return h8->to_ruby(object()->Get(v8_name));
	}

	VALUE get_index(VALUE index) {
		H8::Scope scope(h8);
		return h8->to_ruby(object()->Get(NUM2INT(index)));
	}

	/**
	 * @return true if the object is a primitive string
	 */
	VALUE is_string() {
		H8::Scope scope(h8);
        return value()->IsString() ? Qtrue : Qfalse;
	}

	VALUE is_undefined() {
		H8::Scope scope(h8);
		return value()->IsUndefined() ? Qtrue : Qfalse;
	}

	~JsGate() {
		persistent_value.Reset();
	}

	virtual Local<Value> value() const {
		return Local<Value>::New(h8->getIsolate(), persistent_value);
	}

	virtual Isolate* isolate() {
		return h8->getIsolate();
	}

private:
	friend void rvalue_mark(void* ptr);
	friend class H8;

	H8 *h8=0;
	Persistent<Value> persistent_value;
};

}

#endif
