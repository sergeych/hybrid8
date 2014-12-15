#ifndef __ruby_gate_h
#define __ruby_gate_h

#include "h8.h"
#include "object_wrap.h"

namespace h8 {


	/**
	 * Gate a generic ruby object to Javascript context and retain it for
	 * the lidetime of the javascript object
	 */
    class RubyGate : public ObjectWrap {
    public:

        RubyGate(H8* _context,VALUE object) : context(_context), ruby_object(object),
        next(0), prev(0) {
        	v8::HandleScope scope(context->getIsolate());
//        	printf("Ruby object gate constructor\n");
        	context->add_gate(this);

        	v8::Local<v8::ObjectTemplate> templ = ObjectTemplate::New();
        	templ->SetInternalFieldCount(1);
        	templ->SetCallAsFunctionHandler(&ObjectCallback);
        	Wrap(templ->NewInstance());
        	MakeWeak();
        }

        void setRubyInstance(VALUE instance) {
            this->ruby_object = instance;
        }

        virtual ~RubyGate() {
        	printf("------------------ Ruby object gate destructor\n");
            context->remove_gate(this);
        }

    private:

        void doObjectCallback(const v8::FunctionCallbackInfo<v8::Value>& args);

        static void ObjectCallback(const v8::FunctionCallbackInfo<v8::Value>& args);

        friend class H8;

        H8 *context;
        VALUE ruby_object = Qnil;

        RubyGate *next, *prev;
    };
}


#endif
