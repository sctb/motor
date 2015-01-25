;; -*- mode: lisp -*-

(define motor (require 'motor))

(define create (fd)
  (obj fd: fd
       buffer: ""
       pos: 0))

(define fill (s)
  (let (b (motor.receive s.fd))
    (when b
      (cat! s.buffer b)
      #t)))

(define before (s pat)
  (let (i nil)
    (while (nil? i)
      (let (n (search s.buffer pat s.pos))
        (if (nil? n)
            (unless (fill s)
              (set i -1))
          (set i n))))
    (when (>= i 0)
      (let (n s.pos)
        (set s.pos i)
        (clip s.buffer n i)))))

(define line (s pat)
  (let (p (or pat "\n")
        b (before s p))
    (inc s.pos (# p))
    b))

(define amount (s n)
  (while (< (- (# s.buffer) s.pos) n)
    (unless (fill s)
      (break)))
  (let (b (clip s.buffer s.pos))
    (inc s.pos (# b))
    b))

(define emit (s b)
  (motor.send s.fd b))

(export create
        line
        amount
        emit)
