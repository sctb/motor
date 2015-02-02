;; -*- mode: lisp -*-

(define ffi (require 'ffi))

(define default-size 4096)

(define create (n)
  (let (n (or n default-size))
    (obj length: 0
         storage: (ffi.new "char[?]" n)
         capacity: n)))

(define extend (b n)
  (let (a (create (+ b.capacity n)))
    (ffi.copy b.storage a.storage b.length)
    a))

(define pointer (b)
  (+ b.storage b.length))

(define space (b)
  (- b.capacity b.length))

(define string (b)
  (ffi.string b.storage b.length))

(export create
        extend
        pointer
        space
        string)
