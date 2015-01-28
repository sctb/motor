;; -*- mode: lisp -*-

(define ffi (require 'ffi))

(define-c ffi |
struct sockaddr_in {
  uint8_t               sin_len;
  sa_family_t           sin_family;
  in_port_t             sin_port;
  struct in_addr        sin_addr;
  char                  sin_zero[8];
};
|)

(define-global SOL_SOCKET 0xffff)
(define-global SO_REUSEADDR 0x0004)
