#lang setup/infotab
(define collection 'multi)
(define name "memoize-test")
(define blurb
  (list "Tests for memoize-lib."))
(define categories '(misc))
(define release-notes
  '((p "Updated for Racket.")))
(define repositories '("4.x"))
(define required-core-version "5.0")
(define version "3.0")
(define deps (list "base"
                   "rackunit-lib"
                   "memoize-lib"))
