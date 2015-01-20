;; -*- mode: lisp -*-

(define ffi (require 'ffi))
(define-local c ffi.C)

(define-macro define-c (x)
  (cat "|ffi.cdef[[" (inner x) "]]|"))

(define-c |
int socket(int domain, int type, int protocol);

typedef int socklen_t;

int bind(
  int socket,
  const struct sockaddr *address,
  socklen_t address_len);

int listen(int socket, int backlog);

int accept(
  int socket,
  struct sockaddr *restrict address,
  socklen_t *restrict address_len);

typedef uint8_t sa_family_t;
typedef uint16_t in_port_t;
typedef uint32_t in_addr_t;

struct in_addr {
  in_addr_t     s_addr;
};

struct sockaddr_in {
  uint8_t               sin_len;
  sa_family_t           sin_family;
  in_port_t             sin_port;
  struct in_addr        sin_addr;
  char                  sin_zero[8];
};

uint32_t htonl(uint32_t hostlong);
uint16_t htons(uint16_t hostshort);
char * inet_ntoa(struct in_addr in);

typedef unsigned int nfds_t;

struct pollfd {
  int   fd;
  short events;
  short revents;
};

int poll(struct pollfd *fds, nfds_t nfds, int timeout);
int close(int fildes);

char *strerror(int errnum);

typedef unsigned int size_t;
typedef int ssize_t;

ssize_t read(int fildes, void *buf, size_t nbyte);
ssize_t write(int fildes, const void *buf, size_t nbyte);
|)

(define-local abort (name)
  (let (e (ffi.string (c.strerror (ffi.errno))))
    (error (cat (or name 'error) ": " e))))

(define-local PF_INET 2)
(define-local AF_INET 2)
(define-local INADDR_ANY 0)
(define-local SOCK_STREAM 1)
(define-local IPPROTO_TCP 6)

(define-local socket ()
  (let (s (c.socket PF_INET SOCK_STREAM IPPROTO_TCP))
    (when (< s 0)
      (abort 'socket))
    s))

(define-local close (s)
  (when (< (c.close s) 0)
    (abort 'close)))

(define-local bind (port)
  (let (s (socket)
        p (ffi.new "struct sockaddr_in[1]")
        n (ffi.sizeof "struct sockaddr_in")
        a (get p 0))
    (set a.sin_family AF_INET)
    (set a.sin_port (c.htons port))
    (set a.sin_addr.s_addr INADDR_ANY)
    (let (p (ffi.cast "struct sockaddr*" p)
          x (c.bind s p n))
      (when (< x 0)
        (abort 'bind)))
    (let (x (c.listen s 10))
      (when (< x 0)
        (abort 'listen)))
    s))

(define-local POLLNONE 0x0000)
(define-local POLLIN 0x0001)
(define-local POLLOUT 0x0004)
(define-local POLLERR 0x0008)
(define-local POLLHUP 0x0010)
(define-local POLLNVAL 0x0020)

(define-local threads (obj))

(define-local error? (v)
  (> v 0x0007))

(define-local enter (s t rest: vs)
  (let (v (apply bit.bor vs))
    (set (get threads s) (list t v s))))

(define-local leave (s)
  (set (get threads s) nil)
  (close s))

(define-local run (t s)
  (let (|b,e| (resume t s))
    (unless b
      (pr "error:" e))
    (when (dead? t)
      (leave s))))

(define-local polls ()
  (let (ps ())
    (each (_ (t v s)) threads
      (let (p (ffi.new "struct pollfd"))
        (set p.fd s)
        (set p.events v)
        (add ps p)))
    ps))

(define-local tick (a n)
  (for (i n)
    (let ((fd: s revents: r) (get a i)
          (t v) (get threads s))
      (if (or (dead? t) (error? r))
          (leave s)
          (or (= v POLLNONE) (> r 0))
          (run t s)))))

(define-local IMMEDIATE 0)
(define-local NEVER -1)

(define timeout ()
  (if (find (fn ((_ v)) (= v POLLNONE)) threads)
      IMMEDIATE
    NEVER))

(define loop ()
  (while (not (empty? threads))
    (let (p (polls)
          n (# p)
          a (ffi.new "struct pollfd[?]" n p)
          t (timeout p))
      (c.poll a n t)
      (tick a n))))

(define-local accept (s)
  (let (s (c.accept s nil nil))
    (when (< s 0)
      (abort 'accept))
    s))

(define listen (port f)
  (define-local connect (s)
    (let (s (accept s)
          t (thread f))
      (enter s t POLLNONE))
    ;; handle next connection
    (connect (yield)))
  (let (s (bind port)
        t (thread connect))
    (enter s t POLLIN)))

(define-local wait (s v)
  (let (x (get threads s))
    (set (at x 1) v)
    (yield)))

(define-local BUFFER_SIZE 1024)

(define receive (s)
  (wait s POLLIN)
  (let (b (ffi.new "char[?]" BUFFER_SIZE)
        x (c.read s b BUFFER_SIZE))
    (when (< x 0)
      (abort))
    (when (> x 0)
      (ffi.string b))))

(define send (s b)
  (wait s POLLOUT)
  (let (x (c.write s b (# b)))
    (when (< x 0)
      (abort))
    x))
