;; -*- mode: lisp -*-

(define-local handle (s)
  (let (msg "")
    (define-local p args
      (cat! msg (apply cat args) "\n"))
    (let ((:method :path :version) (start s))
      (p "Method: " method)
      (p "Path: " path)
      (p "Version: " version)
      (p "Headers:")
      (let (x (headers s))
        (each (k v) x
          (p "  " k ": " v)))
      (let (n (number x.Content-Length))
        (when n
          (p "Content:")
          (p (body s n)))))
    (respond s msg)))

(let (port (number (at arg 0)))
  (when port
    (serve port handle)))
