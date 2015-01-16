;; -*- mode: lisp -*-

(define echo (fd)
  (let (b (receive fd))
    (when b
      (send b fd)
      (echo (yield)))))

(define connect (s)
  (let (fd (accept s))
    (enter echo fd POLLIN))
  (connect (yield)))

(define start (port)
  (let (s (listen port))
    (enter connect s POLLIN)
    (loop)))

(let (port (number (at arg 0)))
  (when port (start port)))
