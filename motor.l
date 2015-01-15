;; -*- mode: lisp -*-

(define ffi (require 'ffi))

(define-macro define-c (x)
  (cat "|ffi.cdef[[" (inner x) "]]|"))
