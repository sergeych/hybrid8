/*
 * JsCatcher.h
 *
 *  Created on: Dec 23, 2014
 *      Author: sergeych
 */

#ifndef JSCATCHER_H_
#define JSCATCHER_H_

#include <include/v8.h>
#include "h8.h"

namespace h8 {

class H8;

class JsCatcher : public v8::TryCatch {
public:
	JsCatcher(H8* h8);

	void throwIfCaught();
private:
	H8* h8;
};

} /* namespace h8 */

#endif /* JSCATCHER_H_ */
