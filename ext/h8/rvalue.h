#ifndef _rvalue_h
#define _rvalue_h

namespace h8 {

class RValue {
public:

    void setValue(Handle<Value> val) {
        value = val;
    }

    VALUE to_s() {
//        String::Utf8Value res(value);
//        return *res ? rb_str_new2(*res) : Qnil;
        return rb_str_new2("--1");
    }

    VALUE to_i() {
        return INT2FIX(value->IntegerValue());
    }

    VALUE is_int() {
        return value->IsInt32() ? Qtrue : Qfalse;
    }
    VALUE is_float() {
        return value->IsNumber() ? Qtrue : Qfalse;
    }

    VALUE is_string() {
        return value->IsString() ? Qtrue : Qfalse;
    }
private:
    Handle<Value> value;
};

}

#endif
