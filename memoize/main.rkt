#lang racket

(provide define/memo memo-lambda define/memo* memo-lambda*)

(define undefined (letrec ([x x]) x))

(define (assoc/inner-eq arglist cache)
  (cond
    [(null? cache) #f]
    [(let loop ([left arglist]
                [right (caar cache)])
       (cond
         [(and (null? left) (null? right)) #t]
         [(null? left) #f]
         [(null? right) #f]
         [else (and (eq? (car left) (car right))
                    (loop (cdr left) (cdr right)))]))
     (car cache)]
    [else (assoc/inner-eq arglist (cdr cache))]))

;; extracts the argument list from a procedure definition via LAMBDA or DEFINE
(define-for-syntax (lambda-or-define-args lambda-or-define args)
  (cond
    [(free-identifier=? lambda-or-define #'lambda) args]
    [(free-identifier=? lambda-or-define #'define)
     (with-syntax ([(name . rest) args])
       #'rest)]
    [else (raise-syntax-error 'memoize "internal error" lambda-or-define)]))

;; creates a local binding using LET or internal DEFINE depending on context
(define-syntax local-declaration
  (syntax-rules (lambda define)
    [(_ lambda ([var binding] ...) body)
     (let ([var binding] ...) body)]
    [(_ define ([var binding] ...) body)
     (begin (define var binding) ... body)]))

(define-syntax (memo-lambda-or-define/memo stx)
  (syntax-case stx ()
    [(_ lambda-or-define build-hash-table hash-code assoc args body0 body1 ...)
     (syntax-case (lambda-or-define-args #'lambda-or-define #'args) ()
       [()
        #'(local-declaration lambda-or-define ([cached? #f] [cache undefined])
            (lambda-or-define args
              (unless cached?
                (set! cache (let () body0 body1 ...))
                (set! cached? #t))
              cache))]
       [(arg)
        #'(local-declaration lambda-or-define ([cache build-hash-table])
            (lambda-or-define args
              (hash-ref cache arg (lambda ()
                                    (let ([ans (let () body0 body1 ...)])
                                      (hash-set! cache arg ans)
                                      ans)))))]
       [multiple-args
        (let loop ([arg-exp #'multiple-args] [fixed-args null])
          (syntax-case arg-exp ()
            [(arg . rest)
             (loop #'rest (cons #'arg fixed-args))]
            [rest
             (with-syntax ([list-exp (let loop ([fixed-args fixed-args]
                                                [result (syntax-case #'rest ()
                                                          [() #''()] ;; PLT v4 doesn't allow () as an expression form
                                                          [_ #'rest])])
                                       (if (null? fixed-args)
                                           result
                                           (loop (cdr fixed-args)
                                                 #`(cons #,(car fixed-args) #,result))))])
               ;; NOTE: once we've created the (equal?-based) hash code,
               ;;       we can just store it in an eq?-based hash table.
               #'(local-declaration lambda-or-define ([cache (make-hasheq)])
                   (lambda-or-define args
                     (let* ([arg-list list-exp]
                            [key (apply bitwise-xor (map hash-code arg-list))]
                            [alist (hash-ref cache key (lambda () null))])
                       (cond
                         [(assoc arg-list alist) => cdr]
                         [else (let ([ans (let () body0 body1 ...)])
                                 (hash-set! cache key (cons (cons arg-list ans) alist))
                                 ans)])))))]))])]))

(define-syntax memo-lambda
  (syntax-rules ()
    [(_ args body0 body1 ...)
     (memo-lambda-or-define/memo lambda (make-hasheq) eq-hash-code assoc/inner-eq args body0 body1 ...)]))

(define-syntax memo-lambda*
  (syntax-rules ()
    [(_ args body0 body1 ...)
     (memo-lambda-or-define/memo lambda (make-hash) equal-hash-code assoc args body0 body1 ...)]))

(define-syntax define/memo
  (syntax-rules ()
    [(_ args body0 body1 ...)
     (memo-lambda-or-define/memo define (make-hasheq) eq-hash-code assoc/inner-eq args body0 body1 ...)]))

(define-syntax define/memo*
  (syntax-rules ()
    [(_ args body0 body1 ...)
     (memo-lambda-or-define/memo define (make-hash) equal-hash-code assoc args body0 body1 ...)]))
