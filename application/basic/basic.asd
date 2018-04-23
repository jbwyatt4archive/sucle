(asdf:defsystem #:basic
  :depends-on (#:application
	       #:utility
	       #:doubly-linked-list
	       #:text-subsystem
	       #:opengl-immediate
	       #:image-utility
	       #:character-modifier-bits
	       #:terminal-3bst-sbcl
	       #:uncommon-lisp
	       #:testbed
	       #:quads
	       #:point)
  :serial t
  :components 
  ((:file "sprite-chain")
   (:file "basic")))
