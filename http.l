;; -*- mode: lisp -*-

(define serve (port f)
  (define-local connect (s)
    (f s))
  (listen port connect)
  (loop))
