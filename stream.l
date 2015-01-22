;; -*- mode: lisp -*-

(define stream (fd)
  (obj fd: fd
       buffer: ""
       pos: 0))

(define-local fill (s)
  (let (b (receive s.fd))
    (when b
      (cat! s.buffer b)
      #t)))

(define before (s pat)
  (let (i nil)
    (while (nil? i)
      (let (n (search s.buffer pat))
        (if (nil? n)
            (unless (fill s)
              (set i -1))
          (set i n))))
    (when (>= i 0)
      (set s.pos i)
      (clip s.buffer 0 i))))

(define line (s pat)
  (let (p (or pat "\n")
        b (before s p))
    (inc s.pos (# p))
    b))

(define write (s b)
  (send s.fd b))
