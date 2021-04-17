#lang setup/infotab
(define collection 'multi)
(define name "memoize-doc")
(define blurb
  (list "Documentation memoize-lib."))
(define categories '(misc))
(define scribblings '(("memoize.scrbl" ())))
(define release-notes
  '((p "Updated for Racket.")))
(define repositories '("4.x"))
(define required-core-version "5.0")
(define version "3")
(define deps (list "base"
                   "rackunit-lib"))
(define build-deps (list "scribble-lib"
                         "racket-doc"
                         "memoize-lib"))
