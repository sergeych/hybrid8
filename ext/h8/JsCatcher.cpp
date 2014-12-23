/*
 * JsCatcher.cpp
 *
 *  Created on: Dec 23, 2014
 *      Author: sergeych
 */

#include "JsCatcher.h"

namespace h8 {


JsCatcher::JsCatcher(H8* h8) : h8(h8), v8::TryCatch(h8->getIsolate()) {}

void JsCatcher::throwIfCaught() {
	if( HasCaught() ) {
		if( !CanContinue() && HasTerminated() ) {
			h8->getIsolate()->CancelTerminateExecution();
		}
		throw JsError(h8, Message(), Exception());
	}
}

} /* namespace h8 */
