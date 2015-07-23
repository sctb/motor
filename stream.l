;; -*- mode: lisp -*-

(define motor (require 'motor))
(define buffer (require 'buffer))

(define create (fd)
  (list fd: fd
        buffer: (buffer.create)
        pos: 0))

(define space (s) (buffer.space s.buffer))
(define length (s) (buffer.length s.buffer))
(define full? (s) (buffer.full? s.buffer))
(define extend (s n) (buffer.extend s.buffer n))
(define read (s) (motor.read s.fd s.buffer))

(define string (s n)
  (buffer.string s.buffer s.pos n))

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
        (inc s.pos n)))))

(define line (s pat)
  (let p (or pat "\n")
    (with x (before s p)
      (inc s.pos (# p)))))

(define take (s n)
  (when (< (space s) n)
    (extend s n))
  (while (< (- (length s) s.pos) n)
    (unless (fill s)
      (break)))
  (with x (string s n)
    (inc s.pos (# x))))

(define emit (s b)
  (motor.send s.fd b))

(export create
        line
        take
        emit)
