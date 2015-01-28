;; -*- mode: lisp -*-

(define ffi (require 'ffi))

(define-c ffi |
struct sockaddr_in {
  sa_family_t           sin_family;
  in_port_t             sin_port;
  struct in_addr        sin_addr;
  unsigned char         sin_zero[9];
};
|)

(define-global SOL_SOCKET 1)
(define-global SO_REUSEADDR 2)
