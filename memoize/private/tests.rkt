#lang racket

(require rackunit
         rackunit/text-ui
         racket/class
         "../../main.rkt")
(provide all-tests)

(define number-of-runs (make-parameter 0))
(define (increment!)
  (number-of-runs (add1 (number-of-runs))))

(define-struct memoize-result (results run-count) #:transparent)

(define-syntax run/memo
  (syntax-rules (memo-lambda define/memo define/memo/class)
    [(_ (memo-lambda formals body0 body1 ...) actual ...)
     (parameterize ([number-of-runs 0])
       (let* ([p (memo-lambda formals
                   (increment!)
                   body0 body1 ...)]
              [results (build-list 50 (lambda (i) (p actual ...)))])
         (make-memoize-result results (number-of-runs))))]
    [(_ (define/memo (name . formals) body0 body1 ...) actual ...)
     (parameterize ([number-of-runs 0])
       (define/memo (p . formals)
         (increment!)
         body0 body1 ...)
       (let ([results (build-list 50 (lambda (i) (p actual ...)))])
         (make-memoize-result results (number-of-runs))))]
    [(_ (define/memo/class (name . formals) body0 body1 ...) actual ...)
     (parameterize ([number-of-runs 0])
       (define c%
         (class object%
           (public name)
           (define/memo (name . formals)
             (increment!)
             body0 body1 ...)
           (super-new)))
       (let* ([object (new c%)]
              [results (build-list 50 (lambda (i) (send object name actual ...)))])
         (make-memoize-result results (number-of-runs))))]))


(define-simple-check (check-memo actual expected)
  (with-check-info (['memoize-result "not a memoized result"])
    (unless (memoize-result? actual)
      (fail-check)))
  (with-check-info (['consistent-results "did not return consistent results"])
    (unless (andmap (lambda (elt) (eq? elt expected)) (memoize-result-results actual))
      (fail-check)))
  (with-check-info (['ran-once "did not run exactly once"])
    (unless (= (memoize-result-run-count actual) 1)
      (fail-check))))

;    (and (memoize-result? actual)
;         (with-check-info ([
;         (andmap (lambda (elt) (eq? elt expected)) (memoize-result-results actual))
;         (= (memoize-result-run-count actual) 1)))

(define memo-lambda-tests
  (test-suite
    "memo-lambda tests"
    (test-case "memo-lambda with zero arguments"
      (check-memo (run/memo (memo-lambda () 3))
                  3))
    (test-case "memo-lambda with one argument"
      (check-memo (run/memo (memo-lambda (a) (add1 a)) 2)
                  3))
    (test-case "memo-lambda with four arguments"
      (check-memo (run/memo (memo-lambda (a b c d) (+ a b c d)) 1 3 7 15)
                  26))
    (test-case "memo-lambda with 2 fixed args and variable arity"
      (check-memo (run/memo (memo-lambda (a b . rest) (apply + (cons a (cons b rest)))) 1 3 7 15)
                  26))
    (test-case "memo-lambda with totally variable arity"
      (check-memo (run/memo (memo-lambda args (apply + args)) 1 3 7 15)
                  26))
    ))

(define define/memo-tests
  (test-suite
    "define/memo tests"
    (test-case "define/memo with zero arguments"
      (check-memo (run/memo (define/memo (p) 3))
                  3))
    (test-case "define/memo with one argument"
      (check-memo (run/memo (define/memo (p a) (add1 a)) 2)
                  3))
    (test-case "define/memo with four arguments"
      (check-memo (run/memo (define/memo (p a b c d) (+ a b c d)) 1 3 7 15)
                  26))
    (test-case "define/memo with 2 fixed args and variable arity"
      (check-memo (run/memo (define/memo (p a b . rest) (apply + (cons a (cons b rest)))) 1 3 7 15)
                  26))
    (test-case "memo-lambda with totally variable arity"
      (check-memo (run/memo (define/memo (p . args) (apply + args)) 1 3 7 15)
                  26))
    ))

(define class-tests
  (test-suite
    "compatibility of define/memo and class.ss"
    (test-case "define/memo in a class with zero arguments"
      (check-memo (run/memo (define/memo/class (p) 3))
                  3))
    (test-case "define/memo in a class with one argument"
      (check-memo (run/memo (define/memo/class (p a) (add1 a)) 2)
                  3))
    (test-case "define/memo in a class with four arguments"
      (check-memo (run/memo (define/memo/class (p a b c d) (+ a b c d)) 1 3 7 15)
                  26))
    (test-case "define/memo in a class with 2 fixed args and variable arity"
      (check-memo (run/memo (define/memo/class (p a b . rest) (apply + (cons a (cons b rest)))) 1 3 7 15)
                  26))
    (test-case "memo-lambda in a class with totally variable arity"
      (check-memo (run/memo (define/memo/class (p . args) (apply + args)) 1 3 7 15)
                  26))
    ))

(define eq-vs-equal-tests
  (test-suite
   "eq-vs-equal for multiple args"
   (test-case
    "simple test"
    (let ([f (memo-lambda (x y)
               (increment!)
               (+ (string-length x) (string-length y)))]
          [hello "hello"]
          [world "world"])
      (parameterize ([number-of-runs 0])
        (f (string-append "h" "ello")
           (string-append "w" "orld"))
        (f (string-append "he" "llo")
           (string-append "wo" "rld"))
        (with-check-info (['ran-twice "did not run exactly twice"])
          (unless (= (number-of-runs) 2)
            (fail-check))))
      (parameterize ([number-of-runs 0])
        (f hello world)
        (f hello world)
        (with-check-info (['ran-once "did not run exactly once"])
          (unless (= (number-of-runs) 1)
            (fail-check))))))))

;; TODO: eq-vs-equal-tests
;; (define string1 "dave")
;; (define string2 (string-append "da" "ve"))
;; (define/memo (f1 str)
;;   (printf "f1: ~a~n" str)
;;   (string-length str))
;; (define/memo* (f2 str)
;;   (printf "f2: ~a~n" str)
;;   (string-length str))

(define all-tests
  (test-suite
    "all memoize.plt tests"
    memo-lambda-tests
    define/memo-tests
    class-tests
    eq-vs-equal-tests
    ))

(run-tests all-tests)
