;; -*- mode: lisp -*-

(define handle (s)
  (let ((:method :path :version) (start s))
    (respond s (cat method " " path))))

(let (port (number (at arg 0)))
  (when port
    (serve port handle)))
