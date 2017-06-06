;; -*- mode: lisp -*-

(define ffi (require 'ffi))

(define default-size 4096)

(define allocate (n)
  ((get ffi 'new) "char[?]" n))

(define create (n)
  (let n (or n default-size)
    (list length: 0
          storage: (allocate n)
          capacity: n)))

(define length (b) (get b 'length))

(define extend (b n)
  (let (n (if n (+ (get b 'capacity) n) (* (get b 'capacity) 2))
        x (allocate n))
    ((get ffi 'copy) x (get b 'storage) (get b 'length))
    (set (get b 'storage) x)
    (set (get b 'capacity) n)))

(define full? (b)
  (= (get b 'length) (get b 'capacity)))

(define pointer (b)
  (+ (get b 'storage) (get b 'length)))

(define space (b)
  (- (get b 'capacity) (get b 'length)))

(define string (b i n)
  (let (i (or i 0)
        max (- (get b 'length) i)
        n (min (or n max) max))
    (if (< i (get b 'length))
        ((get ffi 'string) (+ (get b 'storage) i) n)
      "")))

(export create
        length
        extend
        full?
        pointer
        space
        string)
