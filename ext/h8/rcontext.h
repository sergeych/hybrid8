#include "h8.h"

#ifndef _context_h
#define _context_h

namespace h8 {
    class RContext {
    public:
        static void init();

        RContext();

        Handle<Value> eval(const char* utf);

        bool isError() {
            return is_error;
        }

        virtual ~RContext();

    private:
        void report_exception(v8::TryCatch& tc);

        Persistent<Context> context;

        bool is_error;
    }; // Context
}

#endif
