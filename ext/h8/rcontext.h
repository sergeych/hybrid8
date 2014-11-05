#include "h8.h"

#ifndef _context_h
#define _context_h

namespace h8 {

    class RContext {
    public:
        static void init();

        RContext() {
//            isolate = Isolate::New();
//            Isolate::Scope isolate_scope(isolate);

            isolate = Isolate::GetCurrent();
        	HandleScope handle_scope(isolate);
        	Handle<ObjectTemplate> global = ObjectTemplate::New();
        	global->Set(String::NewFromUtf8(isolate, "print"), FunctionTemplate::New(isolate, RContext::Print));
        	context = Context::New(isolate, NULL, global);
                context->Enter();
        }

        void eval(const char* utf) {
                	cout << "A" << endl;

            HandleScope handle_scope(isolate);
                    	cout << "b" << endl;

        	cout << "c" << endl;

            Local<String> str(String::NewFromUtf8(isolate, utf));
            Local<String> name(String::NewFromUtf8(isolate, "--eval--"));
        	cout << "3" << endl;

            TryCatch try_catch;

            is_error = false;
        	cout << "e" << endl;

            Handle<Script> script = Script::Compile(str, name);
                    	cout << "0" << endl;

            if (script.IsEmpty()) {
                // Print errors that happened during compilation.
                report_exception(try_catch);
            } else {
        	cout << "1" << endl;
                        	cout << "2" << endl;

                last_result = script->Run();
                        	cout << "3" << endl;

                        	cout << "4" << endl;

                if (last_result.IsEmpty())
                    // Print errors that happened during execution.
                    report_exception(try_catch);
            }
        }

        Handle<Value> getLastResult() const {
            return last_result;
        }

        bool isError() const {
            return is_error;
        }

        virtual ~RContext() {
            context->Exit();
        }

    private:
        Isolate *isolate;
        void report_exception(v8::TryCatch& tc);

        static void Print(const v8::FunctionCallbackInfo<v8::Value>& args);

        Handle<Context> context;
        Handle<Value> last_result;

        bool is_error;
    }; // Context
}

#endif
