**Memoize**: Lightweight Dynamic Programming

by Dave Herman (`dherman at ccs dot neu dot edu`)

Memoize is a simple library for doing dynamic programming in Scheme with
a minimum of effort. The library provides drop-in replacement forms for
defining Scheme functions that cache their results.

    1 Example: Fibonacci  
                          
    2 Forms               
      2.1 Definition Forms
      2.2 Expression Forms

```racket
 (require memoize) package: memoize
```

# 1. Example: Fibonacci

A typical example of a dynamic programming problem is computing the
Fibonacci numbers, whose simplest implementation involves a heavy amount
of duplicated computation. By simply defining the function with
`define/memo`, previously computed answers are cached, avoiding the
duplicated computation.

```racket
Examples:                                           
(define (fib n)                                     
  (if (<= n 1) 1 (+ (fib (- n 1)) (fib (- n 2)))))  
                                                    
                                                    
> (time (fib 35))                                   
cpu time: 513 real time: 522 gc time: 0             
14930352                                            
> (define/memo (fib n)                              
    (if (<= n 1) 1 (+ (fib (- n 1)) (fib (- n 2)))))
                                                    
> (time (fib 35))                                   
cpu time: 0 real time: 0 gc time: 0                 
14930352                                            
```

# 2. Forms

Just like the function definition forms in PLT Scheme, the formals list
of a memoized function may be a single identifier, a proper list of
identifiers, or an improper list of identifiers.

  `formals`` `=` ``id`              
` `        ` `|` ``()`              
` `        ` `|` ``(id` `. formals)`

## 2.1. Definition Forms

```racket
(define/memo (name . formals) body ...)
```

Defines a memoized function `name` with formal arguments `formals` and
function body forms `body ...`. Inputs are cached in a hash table and
looked up with `eq?`.

```racket
(define/memo* (name . formals) body ...)
```

Like `define/memo`, but uses `equal?` to look up values in the cache.

## 2.2. Expression Forms

```racket
(memo-lambda formals body ...)
```

An anonymous memoized function with formal arguments `formals` and
function body forms `body ...`. Inputs are cached in a hash table and
looked up with `eq?`.

```racket
(memo-lambda* formals body ...)
```

Like `memo-lambda`, but uses `equal?` to look up values in the cache.

## License

Copyright © 2012 Dave Herman

Licensed under the [MIT License](http://mit-license.org).
