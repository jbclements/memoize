#lang setup/infotab
(define collection 'multi)
(define name "memoize")

(define deps '("memoize-lib" "memoize-doc" "memoize-test"))
(define implies '("memoize-lib" "memoize-doc" "memoize-test"))

(define blurb
  (list "Macros for defining memoized procedures."))
(define categories '(misc))
(define release-notes
  '((p "Updated for Racket.")))
(define repositories '("4.x"))
(define required-core-version "5.0")
(define version "3")
