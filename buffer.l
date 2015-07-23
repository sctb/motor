;; -*- mode: lisp -*-

(define ffi (require 'ffi))

(define default-size 4096)

(define allocate (n)
  (ffi.new "char[?]" n))

(define create (n)
  (let n (or n default-size)
    (list length: 0
          storage: (allocate n)
          capacity: n)))

(define length (b) b.length)

(define extend (b n)
  (let (n (if n (+ b.capacity n) (* b.capacity 2))
        x (allocate n))
    (ffi.copy x b.storage b.length)
    (set b.storage x)
    (set b.capacity n)))

(define full? (b)
  (= b.length b.capacity))

(define pointer (b)
  (+ b.storage b.length))

(define space (b)
  (- b.capacity b.length))

(define string (b i n)
  (let (i (or i 0)
        max (- b.length i)
        n (min (or n max) max))
    (if (< i b.length)
        (ffi.string (+ b.storage i) n)
      "")))

(export create
        length
        extend
        full?
        pointer
        space
        string)
