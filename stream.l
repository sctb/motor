;; -*- mode: lisp -*-

(define motor (require 'motor))
(define buffer (require 'buffer))

(define create (fd)
  (obj fd: fd
       buffer: (buffer.create)
       pos: 0))

(define fill (s)
  (when (buffer.full? s.buffer)
    (buffer.extend s.buffer))
  (> (motor.read s.fd s.buffer) 0))

(define before (s pat)
  (let (n nil)
    (while (nil? n)
      (let (x (buffer.string s.buffer s.pos)
            m (search x pat))
        (if (nil? m)
            (unless (fill s)
              (set n -1))
          (set n m))))
    (when (>= n 0)
      (let (i s.pos)
        (inc s.pos n)
        (buffer.string s.buffer i n)))))

(define line (s pat)
  (let (p (or pat "\n")
        b (before s p))
    (inc s.pos (# p))
    b))

(define amount (s n)
  (let (b s.buffer)
    (when (< (buffer.space b) n)
      (buffer.extend b n))
    (while (< (- (buffer.length b) s.pos) n)
      (unless (fill s)
        (break)))
    (let (x (buffer.string b s.pos (+ s.pos n)))
      (inc s.pos (# x))
      x)))

(define emit (s b)
  (motor.send s.fd b))

(export create
        line
        amount
        emit)
