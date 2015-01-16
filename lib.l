;; -*- mode: lisp -*-

(define dead? (c)
  (= (coroutine.status c) 'dead))

(define-macro resume args
  `(coroutine.resume ,@args))

(define-macro yield args
  `(coroutine.yield ,@args))

(define thread (f)
  (coroutine.create f))
