#ifndef _rvalue_h
#define _rvalue_h

namespace h8 {

class RValue {
public:

	RValue() {}

    void set(RContext *cxt,Handle<Value> val) {
    	cout << "RESET! " << *val << endl;
    	isolate = cxt->getIsolate();
    	p_value.Reset(isolate, val);
    	value = val;
    	cout << "set done" << endl;
        String::Utf8Value res(value);
        cout << "data " << *res << endl;
    }

    VALUE to_s() {
    	cout << "To_s!" << endl;
		Isolate::Scope isolate_scope(isolate);
    	HandleScope handle_scope(isolate);
    	cout << "Extracting..." << endl;
//    	Local<Value> v = Local<Value>::New(isolate, p_value);
        String::Utf8Value res(value);
    	cout << "Extracted" << endl;
    	cout << "Extracted utf" << endl;
    	cout << "--??? !+ value " << *res << endl;
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

    ~RValue() {
        p_value.Reset();
    }
private:
    Persistent<Value> p_value;
    Handle<Value> value;
    Isolate *isolate;
};

}

#endif
