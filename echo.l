;; -*- mode: lisp -*-

(define connect (fd)
  (let (b (receive fd))
    (while b
      (send fd b)
      (set b (receive fd)))))

(define start (port)
  (listen port connect)
  (loop))

(let (port (number (at arg 0)))
  (when port (start port)))
