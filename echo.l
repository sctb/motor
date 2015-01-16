;; -*- mode: lisp -*-

(define connect (s)
  (let (fd (accept s))
    (pr fd))
  (connect (yield)))

(define start (port)
  (let (s (listen port))
    (enter connect s POLLIN)
    (loop)))

(let (port (number (at arg 0)))
  (when port (start port)))
