#include "h8.h"

#ifndef _context_h
#define _context_h

namespace h8 {

	template <class T> inline void t(const T& x) {
		cout << x << endl;
	}

	class RContext {
		class Scope  : public EscapableHandleScope{
			v8::Isolate::Scope isolate_scope;
			v8::Context::Scope context_scope;
			RContext* rcontext;
		public:
			Scope(RContext* cxt)
			: isolate_scope(cxt->getIsolate()), context_scope(cxt->getContext()),
			  rcontext(cxt), EscapableHandleScope((cxt->getIsolate()))
			{
			}
		};


	public:
		static void init();

		RContext() {
			isolate = Isolate::New();
			Isolate::Scope isolate_scope(isolate);
			HandleScope handle_scope(isolate);

			t("i");
			// Create a template for the global object.
			v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New(isolate);

			// Create a new execution environment containing the built-in
			// functions
			v8::Handle<v8::Context> context = v8::Context::New(isolate, NULL, global);
			persistent_context.Reset(isolate, context);
		}

		void eval(const char* script_utf) {
			t("-1");
//			v8::Isolate::Scope isolate_scope(isolate);
			t("-2");
//			v8::Context::Scope context_scope(getContext());
			t("-3");
			RContext::Scope handle_scope(this);
//			EscapableHandleScope handle_scope(isolate);

			cout << "--------" << endl;
			// Enter the newly created execution environment.
			t("hs!");
			{
				// FIXME!!! Context::Scope should be around all operations with the context (it does Enter/Exit!)


				cout << "A" << endl;

				Handle<v8::String> script_source = String::NewFromUtf8(isolate, script_utf);
				v8::Handle<v8::Script> script;

				t("b");

				// Compile script in try/catch context.
				t("b1");

				v8::TryCatch try_catch;
				t("b2");

				v8::ScriptOrigin origin(String::NewFromUtf8(isolate, "eval"));
				t("c");

				script = v8::Script::Compile(script_source, &origin);

				t("d");

				if (script.IsEmpty()) {
					// Print errors that happened during compilation.
					report_exception(try_catch);
				}
				else {
					t("e");
					lastResult.Reset(isolate, script->Run());
					t("f");

					if (try_catch.HasCaught()) {
						report_exception(try_catch);
					}
					t("g");
				}
			}
			String::Utf8Value u(Local<Value>::New(isolate, lastResult));

			cout << "extracted!"<< endl;
			cout << "Extracted utf" << *u << endl;
		}

		Handle<Context> getContext() {
			return Local<Context>::New(isolate, persistent_context);
		}

		bool isError() const {
			return is_error;
		}

		Isolate* getIsolate() const {return isolate;}

		virtual ~RContext() {
			persistent_context.Reset();
		}

		Persistent<Value,CopyablePersistentTraits<v8::Value>> getLastResult() {return lastResult;}

	private:
		Isolate *isolate;
		void report_exception(v8::TryCatch& tc);

		static void Print(const v8::FunctionCallbackInfo<v8::Value>& args);

		Persistent<Context> persistent_context;

		Persistent<Value,CopyablePersistentTraits<v8::Value>> lastResult;
		bool is_error = false;
	}; // Context
}

#endif
