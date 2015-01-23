;; -*- mode: lisp -*-

(define-local sep "\r\n")
(define-local sep2 (cat sep sep))

(define-local words (x)
  (split x " "))

(define-local cleave (x sep)
  (let (n (search x sep))
    (if (nil? n) x
      (list (clip x 0 n)
            (clip x (+ n (# sep)))))))

(define start (s)
  (let ((m p v) (words (line s sep)))
    (obj method: m
         path: p
         version: v)))

(define headers (s)
  (let (x (obj)
        b (line s sep2))
    (each (_ l) (split b sep)
      (let ((k v) (cleave l ": "))
        (set (get x k) v)))
    x))

(define body (s n)
  (amount s n))

(define-local response (data code)
  (cat "HTTP/1.1 " code sep
       "Content-Length: " (# data) sep2
       data))

(define respond (s data)
  (emit s (response data "200 OK")))

(define problem (s data)
  (emit s (response data "500 Internal Server Error")))

(define unknown (s)
  (emit s (response "Unknown" "404 Not Found")))

(define serve (port f)
  (define-local connect (fd)
    (f (stream fd)))
  (listen port connect)
  (loop))
