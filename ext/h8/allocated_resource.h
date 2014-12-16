#ifndef __allocated_resource
#define __allocated_resource

#include "chain.h"

namespace h8 {

/**
 * Resource that allocates anything that is tied to Isolate and should be
 * freed _before_ isolate is destroyed.
 *
 * (1) derive any of such your resources from it
 * (2) register them in the parent H8 (h8->add_resource())
 * (3) free() resource in free(), then call unlink()/super
 * (4) free all resources in the destructor if any.
 */
class AllocatedResource : public chain::link {
public:
	/**
	 * If your resource references any ruby object, be sure to mark them
	 * all overriding this method!
	 */
	virtual void rb_mark_gc() {};

	virtual void free() {
		unlink();
	};

	/* Default implementation does nothing but call unlink throgh parent
	 * destructor
	 */
	virtual ~AllocatedResource() {};
};

}

#endif
