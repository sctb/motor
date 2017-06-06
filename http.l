;; -*- mode: lisp -*-

(define motor (require 'motor))
(define stream (require 'stream))

(define sep "\r\n")
(define sep2 (cat sep sep))

(define words (x)
  (split x " "))

(define cleave (x sep)
  (let n (search x sep)
    (if (nil? n) x
      (list (clip x 0 n)
            (clip x (+ n (# sep)))))))

(define begin (s)
  (let ((m p v) (words ((get stream 'line) s sep)))
    (list method: m
          path: p
          version: v)))

(define headers (s)
  (with x ()
    (let b ((get stream 'line) s sep2)
      (each l (split b sep)
        (let ((k v) (cleave l ": "))
          (set (get x k) v))))))

(define body (s n)
  ((get stream 'take) s n))

(define response (data code)
  (cat "HTTP/1.1 " code sep
       "Content-Length: " (# data) sep2
       data))

(define respond (s data)
  ((get stream 'emit) s (response data "200 OK")))

(define problem (s data)
  ((get stream 'emit) s (response data "500 Internal Server Error")))

(define unknown (s)
  ((get stream 'emit) s (response "Unknown" "404 Not Found")))

(define serve (port f)
  (define connect (fd)
    (f ((get stream 'create) fd)))
  ((get motor 'listen) port connect)
  ((get motor 'start)))

(export begin
        headers
        body
        respond
        problem
        unknown
        serve)
