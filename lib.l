;; -*- mode: lisp -*-

(define ffi (require 'ffi))
(define-local c ffi.C)

(define-macro define-c (x)
  (cat "|ffi.cdef[[" (inner x) "]]|"))

(define dead? (c)
  (= (coroutine.status c) 'dead))

(define-macro resume args
  `(coroutine.resume ,@args))

(define-macro yield args
  `(coroutine.yield ,@args))

(define thread (f)
  (coroutine.create f))
