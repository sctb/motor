;; -*- mode: lisp -*-

(define connect (s)
  (let (b (receive s))
    (while b
      (send s b)
      (set b (receive s)))))

(define start (port)
  (listen port connect)
  (loop))

(let (port (number (at arg 0)))
  (when port (start port)))
