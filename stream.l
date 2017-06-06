;; -*- mode: lisp -*-

(define motor (require 'motor))
(define buffer (require 'buffer))

(define create (fd)
  (list fd: fd
        buffer: ((get buffer 'create))
        pos: 0))

(define space (s) ((get buffer 'space) (get s 'buffer)))
(define length (s) ((get buffer 'length) (get s 'buffer)))
(define full? (s) ((get buffer 'full?) (get s 'buffer)))
(define extend (s n) ((get buffer 'extend) (get s 'buffer) n))
(define read (s) ((get motor 'read) (get s 'fd) (get s 'buffer)))

(define string (s n)
  ((get buffer 'string) (get s 'buffer) (get s 'pos) n))

(define fill (s)
  (when (full? s)
    (extend s))
  (> (read s) 0))

(define before (s pat)
  (let n nil
    (while (nil? n)
      (let (x (string s)
            m (search x pat))
        (if (nil? m)
            (unless (fill s)
              (set n -1))
          (set n m))))
    (when (>= n 0)
      (with x (string s n)
        (inc (get s 'pos) n)))))

(define line (s pat)
  (let p (or pat "\n")
    (with x (before s p)
      (inc (get s 'pos) (# p)))))

(define take (s n)
  (when (< (space s) n)
    (extend s n))
  (while (< (- (length s) (get s 'pos)) n)
    (unless (fill s)
      (break)))
  (with x (string s n)
    (inc (get s 'pos) (# x))))

(define emit (s b)
  ((get motor 'send) (get s 'fd) b))

(export create
        line
        take
        emit)
