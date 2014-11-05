#ifndef __ruby_gate_h
#define __ruby_gate_h

#include "h8.h"
#include "object_wrap.h"

namespace h8 {

    class RubyWrap : public ObjectWrap {
    public:

        RubyWrap(RContext* ctx) : context(ctx) {
            ctx->registerWrap(this);
        }

        public void setRubyInstance(VALUE instance) {
            this->instance = instance;
        }

        virtual ~RubyWrap() {
            context->unregisterWrap(this);
        }

    private:
        RContext *context;
        VALUE instance = Qnil;

    };
}


#endif
