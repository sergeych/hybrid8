#include "rcontext.h"

using namespace h8;

//Isolate *h8::Context::isolate = NULL;

void RContext::init() {
}

Handle<Value> Print(const Arguments& args) {
	bool first = true;
	for (int i = 0; i < args.Length(); i++) {
		HandleScope handle_scope;
		if (first) {
			first = false;
		} else {
			printf(" ");
		}
		String::Utf8Value str(args[i]);
		cout << *str;
	}
	cout << endl << flush;
//  printf("\n");
//  fflush(stdout);
	return Undefined();
}

RContext::RContext() {
	HandleScope handle_scope;
	Handle<ObjectTemplate> global = ObjectTemplate::New();
	global->Set(String::New("print"), FunctionTemplate::New(Print));
	context = Context::New(NULL, global);
	context->Enter();
}

RContext::~RContext() {
//	cout << "Context++ is destroyed" << endl;
    context->Exit();
    context.Dispose();
}

Handle<Value> RContext::eval(const char* script_plain) {
	// Create a new context.
	HandleScope handle_scope;
	Context::Scope context_scope(context);

	Local<String> str(String::New(script_plain));
	Local<String> name(String::New("--eval--"));

	TryCatch try_catch;

    is_error = false;

    Handle < Script > script = Script::Compile(str, name);
    if (script.IsEmpty()) {
        // Print errors that happened during compilation.
        report_exception(try_catch);
    } else {
        Handle < Value > result = script->Run();
        if (result.IsEmpty())
            // Print errors that happened during execution.
            report_exception(try_catch);
        else
            return result;
    }
	return Undefined();
}

void RContext::report_exception(TryCatch& try_catch) {
	cout << "--- report exception ---" << endl;
	is_error = true;
}
