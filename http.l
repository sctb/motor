;; -*- mode: lisp -*-

(define-local sep "\r\n")
(define-local sep2 (cat sep sep))

(define-local words (x)
  (split x " "))

(define start (s)
  (let ((m p v) (words (line s sep)))
    (obj method: m
         path: p
         version: v)))

(define-local response (data code)
  (cat "HTTP/1.1 " code sep
       "Content-Length: " (# data) sep2
       data))

(define respond (s data)
  (write s (response data "200 OK")))

(define problem (s data)
  (write s (response data "500 Internal Server Error")))

(define unknown (s)
  (write s (response "Unknown" "404 Not Found")))

(define serve (port f)
  (define-local connect (fd)
    (f (stream fd)))
  (listen port connect)
  (loop))
