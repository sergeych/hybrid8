#include "rcontext.h"
#include <list>
//#include "ruby_wrap.h"

using namespace h8;


void RContext::init() {
    v8::V8::InitializeICU();
}

void RContext::Print(const FunctionCallbackInfo<v8::Value>& args) {
	bool first = true;
	for (int i = 0; i < args.Length(); i++) {
        HandleScope handle_scope(args.GetIsolate());
        if (first) {
			first = false;
		} else {
			cout << " ";
		}
		String::Utf8Value str(args[i]);
		cout << *str;
	}
	cout << endl << flush;
}

//RContext::~RContext() {
////	cout << "Context++ is destroyed" << endl;
//    context->Exit();
//    context.Dispose();
//}

//Handle<Value> RContext::eval(const char* script_plain) {
//	// Create a new context.
//	HandleScope handle_scope;
//	Context::Scope context_scope(context);
//
//	Local<String> str(String::New(script_plain));
//	Local<String> name(String::New("--eval--"));
//
//	TryCatch try_catch;
//
//    is_error = false;
//
//    Handle < Script > script = Script::Compile(str, name);
//    if (script.IsEmpty()) {
//        // Print errors that happened during compilation.
//        report_exception(try_catch);
//    } else {
//        Handle < Value > result = script->Run();
//        if (result.IsEmpty())
//            // Print errors that happened during execution.
//            report_exception(try_catch);
//        else
//            return result;
//    }
//	return Undefined();
//}

void RContext::report_exception(TryCatch& try_catch) {
	cout << "--- report exception ---" << endl;
	is_error = true;
}
