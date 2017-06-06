;; -*- mode: lisp -*-

(define-macro define-c (v x)
  (cat "|" v ".cdef[[" (inner x) "]]|"))

(define-macro resume args
  `((get coroutine 'resume) ,@args))

(define-macro yield args
  `((get coroutine 'yield) ,@args))

(define-macro thread args
  `((get coroutine 'create) ,@args))
