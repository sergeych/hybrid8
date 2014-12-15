#ifndef __chain_h
#define __chain_h

#include <assert.h>

/**
 * Copyright (C) by Sergey S. Chernov, iCodici S.n.C
 *
 * Free software under MIT license.
 *
 * Extremely fast minimalistic double linked list.
 *
 * List item derives from chain::link. List item can not be inserted in
 * more than one list. Linking chain::link into other list removes it
 * from any other list. Unlinked chain::link links to self.
 *
 * Not thread safe! Inserting and removing in any position of the list
 * is O(1) operation, iterating is O(N) operation.
 *
 * Typical usages:
 *
 * minimal:
 *     Use any chain::link instance as a root of you list. You can do
 *     everything with it without creating chain instance
 *
 * typical:
 * 	   create chain instance and feed it with chain::instance derivatives.
 * 	   does the same as above but provide more commonly used unterface
 * 	   (actually it is a wrapped chain::link item)
 */
class chain {
public:
	class link;

	/**
	 * Iterator that can iterate over either chain or even chain::link
	 * item (in which case it iterates from a given link and traverses
	 * all the list
	 */
	class iterator {
	public:
		iterator(link *start) :
				current(start) {
		}

		bool operator !=(const iterator& other) const {
			return current != other.current;
		}

		const iterator& operator++() {
			current = current->next;
			return *this;
		}

		link* operator*() const {
			return current;
		}

	private:
		link *current;
	};

	/**
	 * chain list item. Can be used as a list itself: can be iterated, can insert items,
	 * can provide head and tail items and any of its linked items can be easily removed
	 */
	class link {
	public:
		/// Create empty list item (which is locked to itself)
		link() {
			next = prev = this;
		}

		/// Leave whatever chain it is in (or do nothing)
		void unlink() {
			next->prev = prev;
			prev->next = next;
			next = prev = this;
		}

		// Insert in the chain after the specified item
		void link_after(link *left) {
			unlink();
			next = left->next;
			left->next = this;
			prev = left;
			next->prev = this;
		}

		/**
		 * @return true if this is the only item in the list (this is not connected
		 *         to any other item)
		 */
		bool is_disconnected() const {
			return next == prev && next == this;
		}

		/**
		 * Get the next item in the list.
		 *
		 * @return this if the list is empty
		 */
		template<class T>
		T* get_next() {
			return (T*) (next);
		}

		/**
		 * Get the previous item in the list.
		 *
		 * @return this if the list is empty
		 */
		template<class T>
		T* get_prev() {
			return (T*) (prev);
		}

		~link() {
			unlink();
		}

		chain::iterator begin() const {
			return iterator(next);
		}

		chain::iterator end() const {
			return iterator(const_cast<link*>(this));
		}

	private:
		link *next, *prev;
		friend class chain;
	};

	iterator begin() const {
		return root.begin();
	}

	iterator end() const {
		return root.end();
	}

	/**
	 * Add item to the tail of the list
	 */
	void push(link* item) {
		item->link_after(root.prev);
	}

	void push_first(link* item) {
		item->link_after(&root);
	}

	template<class T>
	T* peek_first() {
		return (T*) root.next;
	}

	template<class T>
	T* peek_last() {
		return (T*) root.prev;
	}

	/**
	 * Convenience method: removes head item (if any) and returns it.
	 * Actually, you can get any item from the list (using peek_head(), peek_tail() or iterating
	 * the list) and then remove it from the list (@see chain::link#unlink()) - it is effective and
	 * simple way.
	 *
	 * @return detached head item or NULL
	 */
	template<class T>
	T* pop() {
		if (root.is_disconnected())
			return 0;
		link *first = root.next;
		first->unlink();
		return (T*) first;
	}

	bool is_empty() const {
		return root.is_disconnected();
	}

private:
	// Root item default constructor is enough
	link root;

};

#endif
